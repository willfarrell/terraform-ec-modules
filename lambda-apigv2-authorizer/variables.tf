variable "name" {
  type = string
}

variable "api_id" {
  type = string
}

variable "api_execution_arn" {
  type = string
}

variable "invoke_arn" {
  type = string
}

variable "function_name" {
  type = string
}

variable "payload_format_version" {
  type    = string
  default = "2.0"
}

variable "result_ttl" {
  type        = number
  description = "Time to live (TTL) for cached authorizer results, in seconds. Max: 3600"
  default     = 300
}

variable "enable_simple_responses" {
  type    = bool
  default = true
}

variable "identity_sources" {
  type    = list(string)
  default = []
}