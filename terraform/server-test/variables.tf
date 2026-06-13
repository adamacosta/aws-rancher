variable "ami_owners" {
  default = ["self"]
  description = "List of account IDs or aliases that own the AMI to search for"
  type = list(string)
}

variable "ami_prefix" {
  default = ""
  description = "Prefix of AMI name to search for"
  type = string
}

variable "instance_type" {
  default = "m8a.xlarge"
  description = "Instance type for EC2(s) to create"
  type = string
}

variable "servers" {
  default = 1
  description = "Number of servers to create"
  type = number
}