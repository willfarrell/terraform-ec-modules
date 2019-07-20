resource "aws_eip" "nat" {
  vpc = "true"

  tags = merge(
    local.tags,
    {
      Name = local.name
    }
  )
}

module "ec2" {
  source        = "../base"
  name          = local.name
  vpc_id        = var.vpc_id
  subnet_ids    = [var.public_subnet_id]
  subnet_public = "true"
  image_id      = local.image_id
  instance_type = var.instance_type
  user_data = templatefile("${path.module}/user_data.sh", {
    BANNER                = "NAT ${var.az_name}"
    EIP_ID                = aws_eip.nat.id
    SUBNET_ID             = var.private_subnet_id
    ROUTE_TABLE_ID        = var.route_table_id
    VPC_CIDR              = var.cidr_block
    LOCAL_GROUPS          = ""
  })
  min_size         = 1
  max_size         = 1
  desired_capacity = 1
}

resource "aws_security_group" "nat" {
  name   = "${local.name}-nat-${var.az_name}"
  vpc_id = var.vpc_id

  ingress {
    protocol  = "tcp"
    from_port = 80
    to_port   = 80

    cidr_blocks = [
      var.private_subnet_cidr_block,
    ]
  }

  ingress {
    protocol  = "tcp"
    from_port = 443
    to_port   = 443

    cidr_blocks = [
      var.private_subnet_cidr_block,
    ]
  }

  egress {
    protocol  = "tcp"
    from_port = 80
    to_port   = 80

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  egress {
    protocol  = "tcp"
    from_port = 443
    to_port   = 443

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  tags = merge(
  local.tags,
  {
    Name = "${local.name}-nat-${var.az_name}"
  }
  )
}

# ACL
# See VPC module
