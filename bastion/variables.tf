variable "name" {
}

variable "default_tags" {
  type    = map(string)
  default = {}
}

variable "vpc_id" {
}

variable "network_acl_id" {
}

variable "subnet_ids" {
  type = list(string)
}

variable "account_id" {
  default = ""
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

variable "volume_type" {
  default = "gp2"
}

variable "volume_size" {
  default = "8"
}

variable "iam_user_groups" {
  default = ""
}

variable "iam_sudo_groups" {
  default = ""
}

variable "assume_role_arn" {
}

variable "ami_account_id" {
  type    = string
  default = "self"
}

#variable "key_name" {
#  type = string
#  default = ""
#}

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