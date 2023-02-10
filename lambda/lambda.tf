data "archive_file" "lambda_file" {
  count       = var.source_file != "" ? 1 : 0
  type        = "zip"
  source_file = "${var.source_dir}/${var.source_file}"
  output_path = "/tmp/${var.name}.zip"
}

data "archive_file" "lambda_dir" {
  count       = var.source_file == "" ? 1 : 0
  type        = "zip"
  source_dir  = var.source_dir
  excludes    = var.excludes
  output_path = "/tmp/${var.name}.zip"
}

resource "aws_s3_object" "lambda" {
  count                  = var.s3_bucket == "" ? 0 : 1
  bucket                 = var.s3_bucket
  key                    = "unsigned/${var.name}-${var.source_file != "" ? data.archive_file.lambda_file[0].output_md5 : data.archive_file.lambda_dir[0].output_md5}.zip"
  source                 = var.source_file != "" ? data.archive_file.lambda_file[0].output_path : data.archive_file.lambda_dir[0].output_path
  server_side_encryption = "AES256"
  depends_on             = [
    data.archive_file.lambda_file, data.archive_file.lambda_dir
  ]
}

resource "aws_signer_signing_job" "lambda" {
  profile_name = var.signer_profile_name

  source {
    s3 {
      bucket  = var.s3_bucket
      key     = aws_s3_object.lambda[0].id
      version = "null"
    }
  }

  destination {
    s3 {
      bucket = var.s3_bucket
      prefix = "signed/${var.name}-"
    }
  }

  ignore_signing_job_failure = false
  depends_on                 = [
    aws_s3_object.lambda
  ]
}

resource "aws_lambda_function" "lambda" {
  depends_on = [
    aws_signer_signing_job.lambda
  ]
  function_name                  = var.name
  description                    = local.description
  s3_bucket                      = var.s3_bucket
  s3_key                         = aws_signer_signing_job.lambda.signed_object[0]["s3"][0]["key"]
  role                           = aws_iam_role.lambda.arn
  handler                        = var.handler
  layers                         = var.layers
  runtime                        = var.runtime
  architectures                  = [lower(var.architecture)]
  memory_size                    = var.memory
  reserved_concurrent_executions = var.reserved_concurrency
  timeout                        = var.timeout
  publish                        = true

  code_signing_config_arn = var.code_signing_config_arn

  dynamic "dead_letter_config" {
    for_each = var.edge ? [] : [
      1
    ]
    content {
      target_arn = var.dead_letter_arn
    }
  }

  tracing_config {
    mode = "Active"
  }

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = var.security_group_ids
  }

  dynamic "environment" {
    for_each = var.edge ? [] : [
      1
    ]
    content {
      variables = local.env
    }
  }

  lifecycle {
    ignore_changes = [
      code_signing_config_arn
    ]
  }
}


//resource "aws_lambda_alias" "lambda" {
//  name             = "latest"
//  description      = "points to the latest version"
//  function_name    = aws_lambda_function.lambda.function_name
//  function_version = aws_lambda_function.lambda.version
//}

//resource "aws_lambda_provisioned_concurrency_config" "lambda" {
//  count                             = (var.provisioned_concurrecy == 0) ? 0 : 1
//  function_name                     = aws_lambda_function.lambda.function_name
//  provisioned_concurrent_executions = var.provisioned_concurrecy
//  qualifier                         = aws_lambda_alias.lambda.name
//}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.edge ? "us-east-1." : ""}${var.name}"
  retention_in_days = var.retention_in_days
  kms_key_id        = var.kms_key_arn
}

resource "aws_iam_role" "lambda" {
  name               = "${var.name}-lambda-role"
  assume_role_policy = var.edge ? data.aws_iam_policy_document.edge-lambda.json : data.aws_iam_policy_document.lambda.json
}

data "aws_iam_policy_document" "lambda" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = [
        "lambda.amazonaws.com"
      ]
    }

  }
}

data "aws_iam_policy_document" "edge-lambda" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = [
        "lambda.amazonaws.com",
        "edgelambda.amazonaws.com",
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

# Adds CloudWatch
resource "aws_iam_role_policy_attachment" "cloud-watch" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Add X-Ray
resource "aws_iam_role_policy_attachment" "xray" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}

# Add NetworkInterface
resource "aws_iam_role_policy_attachment" "vpc" {
  count      = length(var.private_subnet_ids) == 0 ? 0 : 1
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaENIManagementAccess"
}

# Cloudwatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  count = var.enable_cloudwatch_dashboard ? 1 : 0

  dashboard_name = "lambda-${aws_lambda_function.lambda.id}"
  dashboard_body = jsonencode({
    "start" : "-PT168H",
    "widgets" : [
      {
        "height" : 9,
        "width" : 12,
        "y" : 0,
        "x" : 0,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            ["AWS/Lambda", "Duration", "FunctionName", aws_lambda_function.lambda.id, { stat : "PR(:1)" }],
            ["...", { stat : "PR(1:1.3)" }],
            ["...", { stat : "PR(1.3:1.69)" }],
            ["...", { stat : "PR(1.69:2.19)" }],
            ["...", { stat : "PR(2.19:2.85)" }],
            ["...", { stat : "PR(2.85:3.7)" }],
            ["...", { stat : "PR(3.7:4.82)" }],
            ["...", { stat : "PR(4.82:6.27)" }],
            ["...", { stat : "PR(6.27:8.15)" }],
            ["...", { stat : "PR(8.15:10.60)" }],
            ["...", { stat : "PR(10.60:13.78)" }],
            ["...", { stat : "PR(17.92:23.29)" }],
            ["...", { stat : "PR(23.29:30.28)" }],
            ["...", { stat : "PR(30.28:39.37)" }],
            ["...", { stat : "PR(39.37:51.18)" }],
            ["...", { stat : "PR(51.18:66.54)" }],
            ["...", { stat : "PR(66.54:86.50)" }],
            ["...", { stat : "PR(86.50:112.45)" }],
            ["...", { stat : "PR(112.45:146.19)" }],
            ["...", { stat : "PR(146.19:190.04)" }],
            ["...", { stat : "PR(190.04:247.06)" }],
            ["..."],
            ["...", { stat : "PR(321.18:)" }]
          ],
          "view" : "bar",
          "stacked" : false,
          "region" : data.aws_region.current.name,
          "stat" : "PR(247.06:321.18)",
          "period" : 900,
          "setPeriodToTimeRange" : true,
          "title" : "Duration Distribution"
        }
      },
      {
        "height" : 3,
        "width" : 6,
        "y" : 0,
        "x" : 18,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            ["AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.lambda.id, { color : "#d62728" }]
          ],
          "sparkline" : false,
          "view" : "singleValue",
          "stacked" : true,
          "region" : data.aws_region.current.name,
          "stat" : "Sum",
          "period" : 900,
          "title" : "",
          "setPeriodToTimeRange" : true,
          "trend" : false
        }
      },
      {
        "height" : 3,
        "width" : 6,
        "y" : 0,
        "x" : 12,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.lambda.id]
          ],
          "sparkline" : false,
          "view" : "singleValue",
          "stacked" : true,
          "region" : data.aws_region.current.name,
          "stat" : "Sum",
          "period" : 900,
          "setPeriodToTimeRange" : true,
          "trend" : false,
          "title" : "",
          "legend" : {
            "position" : "right"
          }
        }
      },
      {
        "height" : 9,
        "width" : 24,
        "y" : 9,
        "x" : 0,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            [
              "AWS/Lambda", "Duration", "FunctionName", aws_lambda_function.lambda.id,
              { stat : "tm99", yAxis : "right", color : "#9467bd" }
            ],
            [".", "Invocations", ".", ".", { yAxis : "left", color : "#bcbd22" }],
            [".", "Errors", ".", ".", { yAxis : "left", color : "#d62728" }]
          ],
          "sparkline" : true,
          "view" : "timeSeries",
          "stacked" : false,
          "region" : data.aws_region.current.name,
          "stat" : "Sum",
          "period" : 900,
          "setPeriodToTimeRange" : false,
          "trend" : true,
          "legend" : {
            "position" : "bottom"
          },
          "title" : "Duration (TM99) x Invocations x Errors",
          "liveData" : false
        }
      },
      {
        "height" : 6,
        "width" : 12,
        "y" : 3,
        "x" : 12,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '/aws/lambda/${aws_lambda_function.lambda.id}' | filter ${var.log_severity_property_name} = 'ERROR'\n| stats count(*) as total by coalesce(${var.log_http_status_code_property_name}, 'unknown')\n| sort ${var.log_http_status_code_property_name} asc",
          "region" : data.aws_region.current.name,
          "stacked" : false,
          "title" : "Error Status Codes",
          "view" : "bar"
        }
      },
      {
        "height" : 9,
        "width" : 12,
        "y" : 18,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '/aws/lambda/${aws_lambda_function.lambda.id}' | fields @message\n| filter errorType = 'error' or ${var.log_severity_property_name} = 'ERROR'\n| sort @timestamp desc",
          "region" : data.aws_region.current.name,
          "title" : "Errors",
          "view" : "table"
        }
      }
    ]
  })
}