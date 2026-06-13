variable "ami_name" {
  description = "Name to give AMI"
  default     = ""
  type        = string
}

variable "aws_region" {
  description = "AWS region to build AMI in"
  default     = "us-east-2"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type to build from"
  default     = ""
  type        = string
}

variable "sles_version" {
  description = "Major.Minor version of SLES to pull base from"
  default     = ""
  type        = string
}

variable "subnet_id" {
  description = "AWS VPC subnet to build AMI in"
  default     = ""
  type        = string
}

variable "vpc_id" {
  description = "AWS VPC to build AMI in"
  default     = ""
  type        = string
}
