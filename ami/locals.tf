data "aws_caller_identity" "current" {
}

data "null_data_source" "pairs" {
  count = length(keys(var.sub_accounts))
  inputs = {
    pairs = format("${values(var.sub_accounts)[count.index]}|%s", join(",${values(var.sub_accounts)[count.index]}|", data.aws_ami.main.*.image_id))
  }
}

locals {
  account_id = data.aws_caller_identity.current.account_id
  pairs       = split(",", join(",", data.null_data_source.pairs.*.outputs.pairs))
}

output "pairs" {
  value = local.pairs
}