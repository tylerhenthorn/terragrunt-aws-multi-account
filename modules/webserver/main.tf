terraform {
  required_version = ">= 1.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  subnets_per_az  = { for subnet in data.aws_subnet.this : subnet.availability_zone => subnet.id... }
  subnets_for_alb = [for az, subnets in local.subnets_per_az : subnets[0]]
}

resource "aws_autoscaling_group" "webserver_example" {
  launch_template {
    id      = aws_launch_template.webserver_example.id
    version = "$Latest"
  }

  vpc_zone_identifier = data.aws_subnets.this.ids

  target_group_arns = [aws_lb_target_group.webserver_example.arn]
  health_check_type = "ELB"

  min_size = var.min_size
  max_size = var.max_size

  tag {
    key                 = "Name"
    value               = var.name
    propagate_at_launch = true
  }
}

resource "aws_launch_template" "webserver_example" {
  name_prefix            = var.name
  image_id               = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.asg.id]
  user_data              = base64encode(templatefile("${path.module}/user-data.sh", { server_port = var.server_port }))
}

resource "aws_security_group" "asg" {
  name = "${var.name}-asg"
  vpc_id = data.aws_vpc.this.id
}

resource "aws_security_group_rule" "asg_allow_http_inbound" {
  type                     = "ingress"
  from_port                = var.server_port
  to_port                  = var.server_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.asg.id
  source_security_group_id = aws_security_group.alb.id
}

resource "aws_lb" "webserver_example" {
  name               = var.name
  load_balancer_type = "application"
  subnets            = local.subnets_for_alb
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.webserver_example.arn
  port              = var.alb_port
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

resource "aws_lb_target_group" "webserver_example" {
  name     = var.name
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.this.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "webserver_example" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webserver_example.arn
  }
}

resource "aws_security_group" "alb" {
  name = "${var.name}-alb"
  vpc_id = data.aws_vpc.this.id
}

resource "aws_security_group_rule" "alb_allow_http_inbound" {
  type              = "ingress"
  from_port         = var.alb_port
  to_port           = var.alb_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_allow_all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}