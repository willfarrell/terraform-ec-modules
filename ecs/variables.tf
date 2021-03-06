variable "name" {
}

variable "default_tags" {
  type    = map(string)
  default = {}
}

variable "vpc_id" {
}

variable "private_subnet_ids" {
  type = list(string)
}

# EC2
variable "image_id" {
  default = ""
}

variable "instance_type" {
  default = "t3.micro"
}

variable "volume_type" {
  default = "gp2"
}

variable "volume_size" {
  default = "30"
}

variable "min_size" {
  default = "2"
}

variable "max_size" {
  default = "2"
}

variable "desired_capacity" {
  default = "2"
}

variable "efs_ids" {
  type    = list(string)
  default = []
}

variable "efs_security_group_ids" {
  type    = list(string)
  default = []
}

variable "key_name" {
  default = ""
}

variable "ami_account_id" {
  type    = string
  default = "self"
}

variable "assume_role_arn" {
  type    = string
  default = ""
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