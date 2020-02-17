variable "name" {
  type = string
}

variable "default_tags" {
  type    = map(string)
  default = {}
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "subnet_public" {
  default = "false"
}

variable "image_id" {
  type = string
  default = ""
}

variable "instance_type" {
  default = "t3.micro"
}

variable "key_name" {
  type = string
  default = ""
}

variable "user_data" {
  type = string
  default = ""
}

variable "volume_type" {
  type = string
  default = "gp2"
}

variable "volume_size" {
  type = number
  default = 8
}

variable "min_size" {
  type = number
  default = 1
}

variable "max_size" {
  type = number
  default = 1
}

variable "desired_capacity" {
  type = number
  default = 1
}

variable "efs_ids" {
  type    = list(string)
  default = []
}

variable "efs_security_group_ids" {
  type    = list(string)
  default = []
}

variable "iam_service" {
  type    = list(string)
  default = ["ec2"]
}

variable "ami_account_id" {
  type    = string
  default = "amazon"
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

