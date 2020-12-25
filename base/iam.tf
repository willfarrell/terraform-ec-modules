resource "aws_iam_role" "main" {
  name = "${local.name}-role"

  assume_role_policy = data.aws_iam_policy_document.main.json
}

data "aws_iam_policy_document" "main" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = local.services
    }
  }
}

resource "aws_iam_instance_profile" "main" {
  name = "${local.name}-instance-profile"
  role = aws_iam_role.main.name
}

resource "aws_iam_role_policy_attachment" "main-cloudwatch-logs" {
  role       = aws_iam_role.main.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_iam_role_policy_attachment" "main-cloudwatch-agent" {
  role       = aws_iam_role.main.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "main-ssm-agent" {
  role       = aws_iam_role.main.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

//resource "aws_iam_role_policy_attachment" "main-ssm-patch" {
//  role       = aws_iam_role.main.name
//  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMPatchAssociation"
//}

resource "aws_iam_role_policy_attachment" "main-xray" {
  role       = aws_iam_role.main.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

