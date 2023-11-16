variable "name" {
  type = string
}
variable "description" {
  type = string
  default = null
}

variable "source_dir" {
  description = "Only supports `source_dir` with `nodejs/node_modules/*` inside"
  type = string
}

variable "excludes" {
  type = list(string)
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

# Layer
variable "license_info" {
  type = string
  default = null
}
variable "compatible_architectures" {
  type = list(string)
  default = ["x86_64","arm64"]
}
variable "compatible_runtimes" {
  type = list(string)
  default = ["nodejs","nodejs18.x","nodejs20.x"]
}

# Layer Perms
#variable "principal" {
#  type = string
#  default = "*" # * == All accounts in org, null == All AWS
#}
#
#variable "organization_id" {
#  type = string
#  default = null
#}
#
#variable "action" {
#  type = string
#  default = "lambda:GetLayerVersion"
#}
