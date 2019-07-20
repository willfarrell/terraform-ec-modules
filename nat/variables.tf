variable "name" {
}

variable "default_tags" {
  type    = map(string)
  default = {}
}

variable "vpc_id" {
  type = string
}

variable "cidr_block" {
  type = string
}

variable "az_name" {
  type = string
}

variable "route_table_id" {
  type = string
}

variable "public_subnet_id" {
  type = string
}

variable "private_subnet_id" {
  type = string
}

variable "private_subnet_cidr_block" {
  type = string
}

# EC2 Variables
variable "image_id" {
  default = ""
}

variable "instance_type" {
  default = "t3.micro"
}

variable "ami_account_id" {
  type    = string
  default = "self"
}
