data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  aws_region = data.aws_region.current.name
  env        = merge({
    AWS_NODEJS_CONNECTION_REUSE_ENABLED = 1
    // Enable keepAlive
    ACCOUNT_ID                          = local.account_id
    NODE_ENV                            = terraform.workspace
  }, var.env)
}

data "null_data_source" "environment" {
  count  = length(keys(local.env))
  inputs = {
    environment = "{\"name\":\"${keys(local.env)[count.index]}\",\"value\":\"${values(local.env)[count.index]}\"}"
  }
}

/*

*/
