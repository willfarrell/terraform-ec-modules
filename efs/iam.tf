resource "aws_iam_policy" "main" {
  name   = "${local.name}-e${aws_efs_file_system.main.id}-policy"
  policy = data.aws_iam_policy_document.main.json
}

data "aws_iam_policy_document" "main" {
  statement {
    effect    = "Allow"
    actions   = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite"
    ]
    resources = [aws_efs_file_system.main.arn]
  }
  statement {
    sid     = "AllowTLSRequestsOnly"
    effect  = "Deny"
    actions = ["elasticfilesystem:*"]
    resources = [
      aws_efs_file_system.main.arn
    ]
    condition {
      test     = "Bool"
      values   = ["false"]
      variable = "aws:SecureTransport"
    }
  }
}