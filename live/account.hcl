locals {
  account_name   = "live"
  aws_account_id = "REPLACE_ME"

  # The IAM role to assume when applying Terraform to this account
  iam_role = "arn:aws:iam::REPLACE_ME:role/terraform"
}