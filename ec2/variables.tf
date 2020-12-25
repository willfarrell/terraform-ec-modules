variable "name" {
}

variable "default_tags" {
  type    = map(string)
  default = {}
}

variable "account_id" {
  default = ""
}

variable "vpc_id" {
}

variable "subnet_ids" {
  type = list(string)
}

variable "subnet_public" {
  default = "false"
}

variable "image_id" {
  default = ""
}

variable "instance_type" {
  default = "t3.micro"
}

variable "spot" {
  default = true
}
variable "key_name" {
  default = ""
}

variable "user_data" {
  default = ""
}

variable "volume_type" {
  default = "gp2"
}

variable "volume_size" {
  default = "8"
}

variable "min_size" {
  default = "1"
}

variable "max_size" {
  default = "1"
}

variable "desired_capacity" {
  default = "1"
}

variable "efs_ids" {
  type    = list(string)
  default = []
}

variable "efs_security_group_ids" {
  type    = list(string)
  default = []
}

variable "ami_account_id" {
  type    = string
  default = "self"
}

// Use format: "45 0,6 * * *" // UTC
variable "schedule_scale_up_recurrence" {
  type = string
  default = ""
}

variable "schedule_scale_down_recurrence" {
  type = string
  default = ""
}

variable "schedule_shut_down_recurrence" {
  type = string
  default = ""
}
