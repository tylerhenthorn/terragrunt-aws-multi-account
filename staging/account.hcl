locals {
  account_name   = "staging"
  aws_account_id = "<AWS_ACCOUNT_ID>"

  # The IAM role to assume when applying Terraform to this account
  iam_role = "arn:aws:iam::<AWS_ACCOUNT_ID>:role/terraform-staging"
}