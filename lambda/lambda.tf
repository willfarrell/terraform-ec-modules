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
  count            = var.s3_bucket == "" ? 0 : 1
  function_name    = "${var.prefix}-${var.name}"
  description      = jsondecode(file("${var.source_dir}/package.json")).description
  s3_bucket        = var.s3_bucket
  s3_key           = aws_s3_bucket_object.lambda[0].id
  source_code_hash = data.archive_file.lambda.output_base64sha256
  role             = aws_iam_role.lambda.arn
  handler          = "index.handler"
  runtime          = "nodejs12.x"
  memory_size      = var.memory
  timeout          = var.timeout
  publish          = true

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
  count            = var.s3_bucket == "" ? 1 : 0
  depends_on       = [
    data.archive_file.lambda]
  function_name    = "${var.prefix}-${var.name}"
  description      = jsondecode(file("${var.source_dir}/package.json")).description
  filename         = data.archive_file.lambda.output_path
  //source_code_hash = data.archive_file.lambda.output_base64sha256
  source_code_hash = filebase64sha256(data.archive_file.lambda.output_path)
  role             = aws_iam_role.lambda.arn
  handler          = "index.handler"
  runtime          = "nodejs12.x"
  memory_size      = var.memory
  timeout          = var.timeout
  publish          = true

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

// Adds CloudWatch
resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

// Add NetworkInterface
resource "aws_iam_role_policy_attachment" "lambda-vpc" {
  count      = length(var.private_subnet_ids) == 0 ? 0 : 1
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaENIManagementAccess"
}