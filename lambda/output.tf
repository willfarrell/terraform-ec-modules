
output "id" {
  value = concat(aws_lambda_function.lambda, aws_lambda_function.lambda-s3)[0].id
}

output "arn" {
  value = concat(aws_lambda_function.lambda, aws_lambda_function.lambda-s3)[0].arn
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
