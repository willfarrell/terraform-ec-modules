output "arn" {
  value = aws_sns_topic.lambda-dlq.arn
}

output "policy_arn" {
  value = aws_iam_policy.lambda-dlq.arn
}

output "sns" {
  value = aws_sns_topic.lambda-dlq
}

output "sqs" {
  value = aws_sqs_queue.lambda-dlq
}