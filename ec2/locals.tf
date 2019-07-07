data "aws_ami" "main" {
  most_recent = true

  filter {
    name = "name"

    values = [
      "amzn2-ami-hvm-*-x86_64-ebs",
    ]
  }

  filter {
    name = "virtualization-type"

    values = [
      "hvm",
    ]
  }

  owners = ["amazon"]
}

module "defaults" {
  source = "git@github.com:willfarrell/terraform-defaults?ref=v0.1.0"
  name   = var.name
  tags   = var.default_tags
}

locals {
  account_id = module.defaults.account_id
  region     = module.defaults.region
  name       = module.defaults.name
  tags       = module.defaults.tags
}

