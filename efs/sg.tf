data "aws_subnet" "main" {
  count = length(var.subnet_ids)
  id = var.subnet_ids[count.index]
}

# For EFS
resource "aws_security_group" "main" {
  name   = "${local.name}-e${aws_efs_file_system.main.id}"
  vpc_id = data.aws_subnet.main[0].vpc_id

  tags = merge(
    local.tags,
    {
      "Name" = "${local.name}-e${aws_efs_file_system.main.id}"
      "EFS" = aws_efs_file_system.main.id
    },
  )
}

resource "aws_security_group_rule" "efs-ingress" {
  security_group_id = aws_security_group.main.id
  type              = "ingress"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  source_security_group_id = aws_security_group.external.id
}

resource "aws_security_group_rule" "efs-egress" {
  security_group_id = aws_security_group.main.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  source_security_group_id = aws_security_group.external.id
}

# For Attaching
resource "aws_security_group" "external" {
  name   = "${local.name}-efs"
  vpc_id = data.aws_subnet.main[0].vpc_id

  tags = merge(
    local.tags,
    {
      "Name" = "${local.name}-efs"
      "EFS" = aws_efs_file_system.main.id
    },
  )
}

resource "aws_security_group_rule" "external-egress" {
  security_group_id = aws_security_group.external.id
  type              = "egress"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  source_security_group_id = aws_security_group.main.id
}

resource "aws_security_group_rule" "external-ingress" {
  security_group_id = aws_security_group.external.id
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  source_security_group_id = aws_security_group.main.id
}