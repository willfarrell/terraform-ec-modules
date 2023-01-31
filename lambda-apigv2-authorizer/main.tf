# Authorizer
resource "aws_apigatewayv2_authorizer" "main" {
  api_id                            = var.api_id
  authorizer_type                   = "REQUEST"
  authorizer_uri                    = var.invoke_arn
  identity_sources                  = var.identity_sources
  name                              = var.name
  authorizer_payload_format_version = var.payload_format_version
  enable_simple_responses           = var.enable_simple_responses
  authorizer_result_ttl_in_seconds  = var.result_ttl
}

resource "aws_lambda_permission" "main" {
  statement_id_prefix = "AllowExecutionFromAPIGateway"
  action              = "lambda:InvokeFunction"
  function_name       = var.function_name
  principal           = "apigateway.${data.aws_partition.current.dns_suffix}"
  source_arn          = "${var.api_execution_arn}/authorizers/${aws_apigatewayv2_authorizer.main.id}"
}