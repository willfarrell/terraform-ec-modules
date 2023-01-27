variable "api_id" {
  type = string
}

variable "api_execution_arn" {
  type = string
}

variable "function_name" {
  type = string
}

variable "description" {
  type = string
}

variable "invoke_arn" {
  type = string
}

variable "method" {
  type = string
}
variable "path" {
  type = string
}

variable "format" {
  type = string
  description = "API gateway format"
  default = "2.0"
}