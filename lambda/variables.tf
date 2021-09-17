variable "prefix" {
  type = string
  default = "default"
}

variable "edge" {
  type = bool
  default = false
}
variable "name" {
  type = string
}

variable "description" {
  type = string
  default = null
}

variable "vpc_id" {
  type = string
  default = ""
}

variable "source_dir" {
  type = string
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

variable "volumes" {
  type = list(map(string))
  default = []
}

variable "provisioned_concurrecy" {
  type = number
  default = 0
}

variable "reserved_concurrency" {
  type = number
  default = -1
}

variable "security_group_ids" {
  type = list(string)
  default = []
}
variable "private_subnet_ids" {
  type = list(string)
  default = []
}

# Lambda@Edge Doesn't support DQL
variable "dead_letter_arn" {
  description = "sns or sqs arn. need to apply sns:Publish or sqs:SendMessage to iam"
  type = string
  default = null
}

variable "code_signing_config_arn" {
  description = ""
  type = string
}

variable "signer_profile_name" {
  type = string
}

# Lambda@Edge Doesn't support process.env
//ACCOUNT_ID = local.account_id
//NODE_ENV   = terraform.workspace
variable "env" {
  type = map(string)
  default = {}
}

variable "s3_bucket" {
  type = string
}

variable "runtime" {
  type = string
  default = "nodejs14.x"
}