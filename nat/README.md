# NAT
Allow traffic from a private subnet out to the internet

## Features
- static ip address
- Auto-scaling across one public subnet
- CloudWatch logging enabled
- CloudWatch agent for collecting additional metrics
- Inspector agent for allowing running of security assessments in Amazon Inspector
- SSM Agent for allowing shell access from Session AWS Systems Manager

## Setup

### Prerequisites
Before using this terraform module, the "nat" and "ec2" AMIs need to be created in all required regions with Packer - https://github.com/tesera/terraform-modules/blob/master/packer/README.md. 

### Module
```hcl-terraform
module "nat" {
  source            = "git@github.com:willfarrell/terraform-ec-modules//nat?ref=v0.0.1"
  #count             = length(module.vpc.public_subnet_ids)
  name              = local.workspace["name"]
  instance_type     = local.workspace["bastion_instance_type"]
  vpc_id            = module.vpc.id
  public_subnet_id  = module.vpc.public_subnet_ids[0]
  private_subnet_id = module.vpc.private_subnet_ids[0]
  iam_user_groups   = local.workspace["bastion_user_group"]
  iam_sudo_groups   = local.workspace["bastion_sudo_group"]
  assume_role_arn   = matchkeys(data.terraform_remote_state.master.bastion_role_arns, keys(data.terraform_remote_state.master.sub_accounts), list(local.workspace["env"]))[0]
}
```

### Create user group
```hcl-terraform
resource "aws_iam_group" "developers" {
  name = "developers"
}
```

## Input

Name                      | Type   | Default                     | Required  | Description
--------------------------|--------|-----------------------------|-----------|-------------
vpc_id                    | string | ``                          | Yes       | VPC id
cidr_block                | string | ``                          | Yes       | CIDR block for the VPC
az_name                   | string | ``                          | Yes       | name of the AZ, ie `ca-central-1a`
route_table_id            | string | ``                          | Yes       | Routing table ID
public_subnet_id          | string | ``                          | Yes       | Public subnet to reside in
private_subnet_id         | string | ``                          | Yes       | Private subnet to connect to the internet
private_subnet_cidr_block | string | ``                          | Yes       | CIDR block on the private subnet
image_id                  | string | `amzn-ami-hvm-*-x86_64-nat` | No        | override image id
instance_type             | string | `t3.micro`                  | No        | override the instance type
ami_account_id            | string | `self`                      | No        | account id where the AMI resides. See [Packer NAT](https://github.com/willfarrell/terraform-ec-modules/tree/master/packer/nat).


## Output
- **public_ip:** public ip
- **security_group_id:** security group applied, add to ingress on private instance security group
- **iam_role_name:** IAM role name to allow extending of the role
- **billing_suggestion:** comments to improve billing cost
