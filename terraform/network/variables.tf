variable "bastion_instance_type" {
  default     = "m8a.2xlarge"
  description = "EC2 instance type for bastion host"
  type        = string
}

variable "cidr" {
  default     = "10.100.0.0/16"
  description = "IPv4 CIDR range for the VPC. The default is chosen to avoid overlap with what seem to be common example ranges."
  type        = string
}

variable "domain" {
  default     = "rgsdemo.com"
  description = "Domain that the VPN server certificate will be a subdomain of. Must be registered via AWS to use ACM."
  type        = string
}

variable "name" {
  default     = "aacosta-demo"
  description = "tag:Name assigned to VPC, which is used by cluster provisioners to automatically find a network to attach to."
  type        = string
}

variable "region" {
  default     = null
  description = "AWS region to put the VPC in."
  type        = string
}

variable "sles_version" {
  default     = "15.7"
  description = "Version of SLES to install onto bastion"
  type        = string
}

variable "vpn_client_cidr" {
  default     = "172.22.0.0/16"
  description = "CIDR range to assign VPC client IPs from. Must not overlap with any subnet the VPC associates with."
  type        = string
}