variable "prefix" {
  type = string
  default = "default"
}

variable "name" {
  type = string
}

variable "ecs_cluster_name" {}

variable "image" {
  type = string
}

variable "vpc_id" {
  type = string
  default = ""
}

variable "cpu" {
  type        = string
  default     = "256"
  description = "1024 = 1vCPU"
}
variable "memory" {
  type        = string
  default     = "1024"
  description = "1024 = 1 GB"
}

variable "volumes" {
  type = list(map(string))
  default = []
}

# Logs
variable "retention_in_days" {
  type = number
  default = 30
}
variable "kms_key_id" {
  type = string
  default = null
}

// Step Function Logic
variable "result" {
  type = map(string)
  default = {}
}

variable "next" {
  type = string
  default = "End"
}

variable "catch" {
  type = map(any)
  default = {}
}

variable "security_group_ids" {
  type = list(string)
  default = []
}
variable "private_subnet_ids" {
  type = list(string)
  default = []
}

variable "env" {
  type = map(string)
  default = {}
}

variable "xray"{
  type = bool
  default = true
}