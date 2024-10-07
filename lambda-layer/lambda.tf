data "archive_file" "layer" {
  type = "zip"
  source_dir = var.source_dir
  excludes = var.excludes
  output_path = "/tmp/${var.name}.zip"
}

resource "aws_s3_object" "layer" {
  bucket = var.s3_bucket
  key = "unsigned/${var.name}-${data.archive_file.layer.output_md5}.zip"
  source = data.archive_file.layer.output_path
  checksum_algorithm     = "SHA256"
  force_destroy          = true # For Object Lock
  depends_on = [
  data.archive_file.layer]
}


resource "aws_signer_signing_job" "layer" {
  profile_name = var.signer_profile_name

  source {
    s3 {
      bucket = var.s3_bucket
      key = aws_s3_object.layer.id
      version = aws_s3_object.layer.version_id
    }
  }

  destination {
    s3 {
      bucket = var.s3_bucket
      prefix = "signed/${var.name}-"
    }
  }

  ignore_signing_job_failure = false
  depends_on = [
    aws_s3_object.layer
  ]
}

resource "aws_lambda_layer_version" "layer" {
  layer_name = var.name
  description = var.description
  license_info = var.license_info
  s3_bucket = var.s3_bucket
  s3_key = aws_signer_signing_job.layer.signed_object[0]["s3"][0]["key"]

  #compatible_architectures = var.compatible_architectures # CompatibleArchitectures are not supported in ca-central-1. Please remove the CompatibleArchitectures value from your request and try again
  compatible_runtimes = var.compatible_runtimes
}

resource "aws_lambda_layer_version_permission" "layer" {
  statement_id   = "account-only"
  layer_name     = aws_lambda_layer_version.layer.layer_arn
  version_number = aws_lambda_layer_version.layer.version
  principal      = local.account_id
  action         = "lambda:GetLayerVersion"
}
