
module "ec2" {
  source        = "../base"
  name          = local.name
  vpc_id        = var.vpc_id
  subnet_ids    = var.subnet_ids
  image_id      = local.image_id
  instance_type = var.instance_type
  spot          = false # TODO remove var.spot
  user_data = templatefile("${path.module}/user_data.sh", {
    IAM_AUTHORIZED_GROUPS = var.iam_user_groups
    SUDOERS_GROUPS        = var.iam_sudo_groups
    ASSUMEROLE            = var.assume_role_arn
  })
  min_size         = local.min_size
  max_size         = local.max_size
  desired_capacity = local.desired_capacity

  volume_size = 8

  schedule_scale_up_recurrence = var.schedule_scale_up_recurrence
  schedule_scale_down_recurrence = var.schedule_scale_down_recurrence
  schedule_shut_down_recurrence = var.schedule_shut_down_recurrence

  # Debug only
  #key_name = var.key_name
}

# extend role
resource "aws_iam_policy" "main-ip" {
  name        = "${local.name}-ip-policy"
  path        = "/"
  description = "${local.name}-ip Policy"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AssociateAddress"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
POLICY

}

resource "aws_iam_role_policy_attachment" "main-ip" {
  role = module.ec2.iam_role_name
  policy_arn = aws_iam_policy.main-ip.arn
}

resource "aws_iam_policy" "main-iam" {
  name = "${local.name}-iam-policy"
  path = "/"
  description = "${local.name} SSH IAM Policy"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": [
        "${var.assume_role_arn}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": "ec2:DescribeTags",
      "Resource": "*"
    },
    {
      "Sid":"UpdateSSMAgent",
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": [
        "arn:aws:s3:::amazon-ssm-${local.region}/*"
      ]
    }
  ]
}
POLICY

}

resource "aws_iam_role_policy_attachment" "main-iam" {
  role       = module.ec2.iam_role_name
  policy_arn = aws_iam_policy.main-iam.arn
}
