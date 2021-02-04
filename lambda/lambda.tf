resource "null_resource" "lambda_build" {

  triggers = {
    source_dir = base64sha256(var.source_dir)
  }

  provisioner "local-exec" {
    command = "cd ${var.source_dir} && npm ci --production --no-audit"
  }
}

# Workaround https://github.com/terraform-providers/terraform-provider-archive/issues/11#issuecomment-368721675
data "null_data_source" "wait_for_build" {
  inputs = {
    lambda_build_id = null_resource.lambda_build.id
    source_dir      = var.source_dir
  }
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = data.null_data_source.wait_for_build.outputs["source_dir"]
  #source_dir = var.source_dir # will trigger evertime
  output_path = "${var.source_dir}-${var.prefix}.zip"
}

resource "aws_s3_bucket_object" "lambda" {
  count                  = var.s3_bucket == "" ? 0 : 1
  key                    = "${var.prefix}-${var.name}-lambda.zip"
  bucket                 = var.s3_bucket
  source                 = data.archive_file.lambda.output_path
  server_side_encryption = "AES256"
  # Used to trigger updates, doesn't work with KMS. 2019-11 (https://www.terraform.io/docs/providers/aws/r/s3_bucket_object.html#etag)
  etag                   = data.archive_file.lambda.output_md5
}

resource "aws_lambda_function" "lambda-s3" {
  count                          = var.s3_bucket == "" ? 0 : 1
  function_name                  = "${var.prefix}-${var.name}"
  description                    = jsondecode(file("${var.source_dir}/package.json")).description
  s3_bucket                      = var.s3_bucket
  s3_key                         = aws_s3_bucket_object.lambda[0].id
  source_code_hash               = data.archive_file.lambda.output_base64sha256
  role                           = aws_iam_role.lambda.arn
  handler                        = "index.handler"
  runtime                        = var.runtime
  memory_size                    = var.memory
  reserved_concurrent_executions = var.reserved_concurrency
  timeout                        = var.timeout
  publish                        = true

  tracing_config {
    mode = "Active"
  }

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = var.security_group_ids
  }

  environment {
    variables = merge({
      ACCOUNT_ID = local.account_id
      NODE_ENV   = terraform.workspace
    }, var.env)
  }
}

resource "aws_lambda_function" "lambda" {
  count                          = var.s3_bucket == "" ? 1 : 0
  depends_on                     = [
    data.archive_file.lambda]
  function_name                  = "${var.prefix}-${var.name}"
  description                    = jsondecode(file("${var.source_dir}/package.json")).description
  filename                       = data.archive_file.lambda.output_path
  source_code_hash               = data.archive_file.lambda.output_base64sha256
  //source_code_hash               = filebase64sha512(data.archive_file.lambda.output_path)
  role                           = aws_iam_role.lambda.arn
  handler                        = "index.handler"
  runtime                        = var.runtime
  memory_size                    = var.memory
  timeout                        = var.timeout
  reserved_concurrent_executions = var.reserved_concurrency
  publish                        = true

  tracing_config {
    mode = "Active"
  }

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = var.security_group_ids
  }

  environment {
    variables = merge({
      AWS_NODEJS_CONNECTION_REUSE_ENABLED = 1
      // Enable keepAlive
      ACCOUNT_ID                          = local.account_id
      NODE_ENV                            = terraform.workspace
    }, var.env)
  }

  dynamic "file_system_config" {
    for_each = var.volumes
    content {
      arn = file_system_config.value["access_point_arn"]
      local_mount_path = file_system_config.value["local_mount_path"]
    }
  }

//  file_system_config {
//    arn = var.volumes[0].access_point_arn
//    local_mount_path = var.volumes[0].file_system_path
//  }

  tags = {}

  /* tags = merge(
   local.tags,
   {
     Name = local.name
   }
   )*/
}

resource "aws_lambda_alias" "lambda" {
  name             = "latest"
  description      = "points to the latest version"
  function_name    = concat(aws_lambda_function.lambda, aws_lambda_function.lambda-s3)[0].function_name
  function_version = concat(aws_lambda_function.lambda, aws_lambda_function.lambda-s3)[0].version
}


//resource "aws_lambda_provisioned_concurrency_config" "lambda" {
//  count                             = (var.provisioned_concurrecy == 0) ? 0 : 1
//  function_name                     = concat(aws_lambda_function.lambda, aws_lambda_function.lambda-s3)[0].function_name
//  provisioned_concurrent_executions = var.provisioned_concurrecy
//  qualifier                         = aws_lambda_alias.lambda.name
//}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.prefix}-${var.name}"
  retention_in_days = 30
}

resource "aws_iam_role" "lambda" {
  name               = "${var.prefix}-${var.name}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda.json
}

data "aws_iam_policy_document" "lambda" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"

      identifiers = [
        "lambda.amazonaws.com"
      ]
    }

  }
}

/*
condition {
  test     = "StringEquals"
  values   = [local.account_id]
  variable = "AWS:SourceAccount"
}
*/

// Adds CloudWatch
resource "aws_iam_role_policy_attachment" "cloud-watch" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

// Add X-Ray
resource "aws_iam_role_policy_attachment" "xray" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}

// Add NetworkInterface
resource "aws_iam_role_policy_attachment" "vpc" {
  count      = length(var.private_subnet_ids) == 0 ? 0 : 1
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaENIManagementAccess"
}