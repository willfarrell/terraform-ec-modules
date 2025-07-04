module "lambda-dlq" {
	count = var.dead_letter_arn == null ? 1 : 0
  source = "../lambda-dlq"
  name              = var.name
  kms_master_key_id = var.kms_key_arn
}

resource "aws_iam_role_policy_attachment" "lambda-dlq" {
	count = var.dead_letter_arn == null ? 1 : 0
    role       = aws_iam_role.lambda.name
    policy_arn = module.lambda-dlq[0].policy_arn
}
