data "aws_ami" "main" {
  most_recent = true

  filter {
    name = "name"

    values = [
      "amzn2-ami-hvm-*-x86_64-bastion",
    ]
  }

  filter {
    name = "virtualization-type"

    values = [
      "hvm",
    ]
  }

  owners = [
    "self",
  ]
}

module "defaults" {
  source = "git@github.com:willfarrell/terraform-defaults?ref=v0.1.0"
  name   = "${var.name}-bastion"
  tags   = var.default_tags
}

locals {
  account_id       = module.defaults.account_id
  region           = module.defaults.region
  name             = module.defaults.name
  tags             = module.defaults.tags
  image_id         = var.image_id != "" ? var.image_id : data.aws_ami.main.image_id
  max_size         = "1"
  min_size         = "1"
  desired_capacity = "1"
}

