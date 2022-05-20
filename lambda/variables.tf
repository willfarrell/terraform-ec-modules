variable "name" {
  type = string
}
variable "description" {
  type = string
  default = null
}

variable "edge" {
  description = "flag if it is a Lambda@Edge"
  type = bool
  default = false
}

variable "source_dir" {
  description = "Only supports `source_dir` with `index.js` inside"
  type = string
}

variable "excludes" {
  type = list(string)
  default = []
}

variable "handler" {
  type = string
  default = "index.handler"
}

variable "layers" {
  type = list(string)
  default = null
}
variable "runtime" {
  type = string
  default = "nodejs16.x"
}
variable "architecture" {
  type = string
  default = "x86_64"
}
variable "timeout" {
  type = string
  default = "5" // CloudFront=5, API Gateway=30, Max=900
  description = "1024 = 1vCPU"
}
variable "memory" {
  type = string
  default = "128"
  description = "1024 = 1 GB"
}

variable "provisioned_concurrecy" {
  type = number
  default = 0
}

variable "reserved_concurrency" {
  type = number
  default = -1
}

# Logs
variable "retention_in_days" {
  type = number
  default = 30
}
variable "kms_key_arn" {
  type = string
  default = null
}

# VPC
variable "vpc_id" {
  type = string
  default = ""
}
variable "security_group_ids" {
  type = list(string)
  default = []
}
variable "private_subnet_ids" {
  type = list(string)
  default = []
}

variable "volumes" {
  type = list(map(string))
  default = []
}

# CI
variable "s3_bucket" {
  type = string
}

variable "code_signing_config_arn" {
  description = ""
  type = string
}

variable "signer_profile_name" {
  type = string
}

# Lambda@Edge Doesn't support DQL
variable "dead_letter_arn" {
  description = "sns or sqs arn. need to apply sns:Publish or sqs:SendMessage to iam"
  type = string
  default = null
}

# Lambda@Edge Doesn't support extra process.env
variable "env" {
  type = map(string)
  default = {}
}



