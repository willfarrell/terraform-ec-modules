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

variable "runtime" {
  type = string
  default = "nodejs14.x"
}
variable "timeout" {
  type = string
  default = "30"
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



