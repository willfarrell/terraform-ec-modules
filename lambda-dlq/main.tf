resource "aws_sns_topic" "lambda-dlq" {
  name = "${var.name}-lambda-dlq"
  kms_master_key_id = var.kms_master_key_id
}

resource "aws_sns_topic_subscription" "lambda-dlq" {
  topic_arn = aws_sns_topic.lambda-dlq.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.lambda-dlq.arn
}

resource "aws_sqs_queue" "lambda-dlq" {
  name = "${var.name}-lambda-dlq"
  message_retention_seconds = 1209600 # 14d

  kms_master_key_id = var.kms_master_key_id
}

data "aws_iam_policy_document" "lambda-dlq" {
  statement {
    sid = "DLQ"
    effect = "Allow"
    actions = ["sns:Publish"]
    resources = [aws_sns_topic.lambda-dlq.arn]
  }
  statement {
    sid = "KMS"
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyPair",
      "kms:GenerateDataKeyPairWithoutPlaintext",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:Decrypt"
    ]
    resources = ["arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/${var.kms_master_key_id}"]
  }
}
resource "aws_iam_policy" "lambda-dlq" {
  name = "${var.name}-lambda-dlq-policy"
  policy = data.aws_iam_policy_document.lambda-dlq.json
}