# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html
data "aws_ami" "main" {
  most_recent = true

  filter {
    name = "name"

    values = [
      "amzn-ami-hvm-*-x86_64-nat",
    ]
  }

  filter {
    name = "virtualization-type"

    values = [
      "hvm",
    ]
  }

  owners = [var.ami_account_id]
}

module "defaults" {
  source = "git@github.com:willfarrell/terraform-defaults?ref=v0.1.0"
  name   = var.name
  tags   = var.default_tags
}

locals {
  account_id       = module.defaults.account_id
  region           = module.defaults.region
  name             = "${module.defaults.name}-ecs"
  tags             = module.defaults.tags
  image_id         = var.image_id != "" ? var.image_id : data.aws_ami.main.image_id
  instance_type    = var.instance_type
}

