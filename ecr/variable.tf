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

variable "expire_untagged_days" {
  type = number
  default = 1
}


# variable "kms_key_arn" {
#   default = null
# }