variable "name" {
  type = string
}

variable "mutability" {
  type = string
  default = "MUTABLE"
}

variable "scanning" {
  type = bool
  default = true
}

variable "sub_accounts" {
  type = map(string)

  default = {
    production  = ""
    staging     = ""
    testing     = ""
    development = ""
  }
}

variable "lifecycle_policy" {
  description = "data.aws_ecr_lifecycle_policy_document.main.json"
  type = string
  default = null
}


# variable "kms_key_arn" {
#   default = null
# }