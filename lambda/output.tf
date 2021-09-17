
output "id" {
  value = aws_lambda_function.lambda.id
}

output "arn" {
  value = aws_lambda_function.lambda.arn
}

output "invoke_arn" {
  description = "For API Gateway"
  value = aws_lambda_function.lambda.invoke_arn
}

output "qualified_arn" {
  description = "For CloudFront"
  value = aws_lambda_function.lambda.qualified_arn
}

output "role" {
  value = aws_iam_role.lambda
}

output "role_arn" {
  value = aws_iam_role.lambda.arn
}

output "role_name" {
  value = aws_iam_role.lambda.name
}

output "description" {
  value = local.description
}