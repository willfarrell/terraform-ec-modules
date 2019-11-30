data "aws_caller_identity" "current" {
}

data "null_data_source" "root" {
  count = length(keys(var.sub_accounts))
  inputs = {
    arns = format("arn:aws:iam::${values(var.sub_accounts)[count.index]}:root")
  }
}

data "null_data_source" "role" {
  count = length(keys(var.sub_accounts))
  inputs = {
    arns = format("arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${keys(var.sub_accounts)[count.index]}-ecr-role")
  }
}

locals {
  account_id   = data.aws_caller_identity.current.account_id
  sub_accounts = var.sub_accounts
  allowed_arns = concat(data.null_data_source.root.*.outputs.arns, data.null_data_source.role.*.outputs.arns) //
}