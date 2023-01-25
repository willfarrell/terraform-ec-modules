# *** SNS *** #
resource "aws_sns_topic" "lambda-dlq" {
  name                             = "${var.name}-lambda-dlq"
  kms_master_key_id                = var.kms_master_key_id
  sqs_success_feedback_role_arn    = aws_iam_role.lambda-dlq-sns.arn
  sqs_success_feedback_sample_rate = 100
  sqs_failure_feedback_role_arn    = aws_iam_role.lambda-dlq-sns.arn
}

resource "aws_iam_role" "lambda-dlq-sns" {
  name               = "${var.name}-lambda-dlq-sns-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.lambda-dlq-sns.json
}

data "aws_iam_policy_document" "lambda-dlq-sns" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["sns.${data.aws_partition.current.dns_suffix}"]
    }
  }
}

resource "aws_iam_role_policy" "lambda-dlq-sns-delivery-status-role-policy" {
  name   = "${var.name}-lambda-dlq-sns-delivery-status-role-policy"
  role   = aws_iam_role.lambda-dlq-sns.id
  policy = data.aws_iam_policy_document.lambda-dlq-sns-delivery-status-role-policy.json
}

data "aws_iam_policy_document" "lambda-dlq-sns-delivery-status-role-policy" {
  statement {
    effect  = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:PutMetricFilter",
      "logs:PutRetentionPolicy"
    ]
    resources = ["*"]
  }
}

# *** SQS *** #
resource "aws_sns_topic_subscription" "lambda-dlq" {
  topic_arn = aws_sns_topic.lambda-dlq.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.lambda-dlq.arn
}

resource "aws_sqs_queue" "lambda-dlq" {
  name                      = "${var.name}-lambda-dlq"
  message_retention_seconds = 1209600 # 14d

  kms_master_key_id = var.kms_master_key_id
}

# *** Lambda Policy *** #
resource "aws_iam_policy" "lambda-dlq" {
  name   = "${var.name}-lambda-dlq-policy"
  policy = data.aws_iam_policy_document.lambda-dlq.json
}

data "aws_iam_policy_document" "lambda-dlq" {
  statement {
    sid       = "DLQ"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.lambda-dlq.arn]
  }
  statement {
    sid     = "KMS"
    effect  = "Allow"
    actions = [
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyPair",
      "kms:GenerateDataKeyPairWithoutPlaintext",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:Decrypt"
    ]
    resources = [
      "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/${var.kms_master_key_id}"
    ]
  }
}


