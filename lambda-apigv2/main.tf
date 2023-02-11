# APIG Endpoint
resource "aws_apigatewayv2_route" "main" {
  api_id             = var.api_id
  route_key          = var.method != null ? "${var.method} ${var.path}" : var.path # http / ws
  target             = "integrations/${aws_apigatewayv2_integration.main.id}"
  authorization_type = var.authorization_type
  authorizer_id      = var.authorizer_id
}
resource "aws_apigatewayv2_integration" "main" {
  description            = var.description
  api_id                 = var.api_id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  payload_format_version = var.method != null ? var.format : null # http / ws
  integration_uri        = var.invoke_arn
}

resource "aws_lambda_permission" "main" {
  statement_id_prefix = "AllowExecutionFromAPIGateway"
  action              = "lambda:InvokeFunction"
  function_name       = var.function_name
  principal           = "apigateway.amazonaws.com"
  source_arn          = "${var.api_execution_arn}/*/*${var.path}"
}


// Warmup
//resource "aws_cloudwatch_event_rule" "warmup" {
//  name = "${var.function_name}-warmup"
//  description = "Trigger warmup"
//
//  schedule_expression = "rate(5 minutes)" // 5min vs 15min (AWS vs VPC)
//}
//
//resource "aws_cloudwatch_event_target" "warmup" {
//  target_id = "${var.function_name}-warmup"
//  rule = aws_cloudwatch_event_rule.warmup.name
//  arn = var.arn
//  input = "{\"event\":{\"source\":\"warmup\"}}"
//}
//
//resource "aws_lambda_permission" "warmup" {
//  statement_id = "AllowExecutionFromCloudWatch"
//  action = "lambda:InvokeFunction"
//  function_name = var.function_name
//  principal = "events.amazonaws.com"
//  source_arn = aws_cloudwatch_event_rule.warmup.arn
//}
