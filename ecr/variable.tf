variable "name" {
  type = string
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
