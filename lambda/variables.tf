variable "name" {
  type = string
}
variable "description" {
  type    = string
  default = null
}

variable "edge" {
  description = "flag if it is a Lambda@Edge"
  type        = bool
  default     = false
}

variable "source_file" {
  description = "Set to file name within source_dir to only use one file"
  type        = string
  default     = ""
}

variable "source_dir" {
  description = "Must not end with trailing /"
  type        = string
}

variable "excludes" {
  type    = list(string)
  default = []
}

variable "handler" {
  type    = string
  default = "index.handler"
}

variable "layers" {
  type    = list(string)
  default = null
}
variable "runtime" {
  type    = string
  default = "nodejs18.x"
}
variable "architecture" {
  type    = string
  default = "arm64"
}
variable "timeout" {
  type        = string
  default     = "5" # CloudFront=5, API Gateway=30, Max=900
  description = "1024 = 1vCPU"
}
variable "memory" {
  type        = string
  default     = "128"
  description = "1024 = 1 GB"
}

variable "provisioned_concurrecy" {
  type    = number
  default = 0
}

variable "reserved_concurrency" {
  type    = number
  default = -1
}

# Logs
variable "retention_in_days" {
  type    = number
  default = 30
}
variable "kms_key_arn" {
  type    = string
  default = null
}

# Cloudwatch
variable "enable_cloudwatch_dashboard" {
  type    = bool
  default = false
}

variable "log_severity_property_name" {
  type        = string
  description = "Property name for severity in error logs"
  default     = "log_level"
}

variable "log_http_status_code_property_name" {
  type        = string
  description = "Property name for status codes in error logs"
  default     = "status_code"
}

# VPC
variable "vpc_id" {
  type    = string
  default = ""
}
variable "security_group_ids" {
  type    = list(string)
  default = []
}
variable "private_subnet_ids" {
  type    = list(string)
  default = []
}

variable "volumes" {
  type    = list(map(string))
  default = []
}

# CI
variable "s3_bucket" {
  type = string
}

variable "code_signing_config_arn" {
  description = ""
  type        = string
}

variable "signer_profile_name" {
  type = string
}

# Lambda@Edge Doesn't support DQL
variable "dead_letter_arn" {
  description = "sns or sqs arn. need to apply sns:Publish or sqs:SendMessage to iam"
  type        = string
  default     = null
}

# Lambda@Edge Doesn't support extra process.env
variable "env" {
  type    = map(string)
  default = {}
}



