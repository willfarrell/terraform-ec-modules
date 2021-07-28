data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  aws_region = data.aws_region.current.name
  description = var.description != "" ? var.description : jsondecode(file("${var.source_dir}/package.json")).description
}
