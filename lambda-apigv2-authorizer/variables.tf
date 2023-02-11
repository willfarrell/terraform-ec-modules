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
  default = "2.0" # to allow websocket, set to null
}

variable "result_ttl" {
  type        = number
  description = "Time to live (TTL) for cached authorizer results, in seconds. Max: 3600"
  default     = 3600 # to allow websocket, set to null
}

variable "enable_simple_responses" {
  type    = bool
  default = true # to allow websocket, set to null
}

variable "identity_sources" {
  type    = list(string)
  default = []
}