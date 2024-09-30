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
  default = null
}
variable "path" {
  type = string
}

variable "format" {
  type        = string
  description = "API gateway format"
  default     = "2.0"
}

variable "authorization_type" {
  type        = string
  description = "Authorization type for the route"
  default     = "NONE" # AWS_IAM
}

variable "authorizer_id" {
  type        = string
  description = "Identifier of the authorizer resource"
  default     = null
}