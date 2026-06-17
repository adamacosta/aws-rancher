variable "ami_id" {
  default     = null
  description = "AMI to use for cluster nodes"
  type        = string
}

variable "availability_zone" {
  default     = "a"
  description = "Suffix of availability zone in selected region"
  type        = string
}

variable "aws_ccm_version" {
  description = "Version of aws-cloud-controller-manager Helm chart to bootstrap with"
  type        = string
}

variable "cp_nodes" {
  default     = 1
  description = "Number of control plane nodes"
  type        = number

  validation {
    condition     = var.cp_nodes == 1 || var.cp_nodes == 3 || var.cp_nodes == 5
    error_message = "Number of control plane nodes must be 1, 3, or 5"
  }
}

variable "iam_instance_profile" {
  default     = null
  description = "Name of EC2 instance profile to assign to cluster nodes"
  type        = string
}

variable "instance_type" {
  default     = "m8a.xlarge"
  description = "EC2 instance type of cluster nodes"
  type        = string
}

variable "labels" {
  default     = {}
  description = "Labels to add to cluster"
  type        = map(string)
}

variable "name" {
  description = "Name of cluster"
  type        = string
}

variable "private_registry" {
  default     = "registry.ranchercarbide.dev"
  description = "Private registry for mirrors and system-default-registry"
  type        = string
}

variable "region" {
  default     = null
  description = "Region to create nodes in"
  type        = string
}

variable "registry_secret" {
  default     = "carbide-registry"
  description = "Secret in fleet-default namespace with basic-auth for system-default-registry"
  type        = string
}

variable "rke2_version" {
  description = "Version of RKE2 to install on cluster"
  type        = string
}

variable "root_disk_size" {
  default     = "40"
  description = "Size in GiB of root volume"
  type        = string
}

variable "security_groups" {
  default     = ["rancher-nodes"]
  description = "List of security groups to add cluster nodes to"
  type        = list(string)
}

variable "ssh_user" {
  default     = "ec2-user"
  description = "Name of cloud-init default for selected AMI"
  type        = string
}

variable "subnet" {
  default     = null
  description = "VPC subnet to create cluster nodes in"
  type        = string
}

variable "volume_type" {
  default     = "gp3"
  description = "EBS volume type for root disk"
  type        = string
}

variable "vpc" {
  default     = null
  description = "VPC to create cluster nodes in"
  type        = string
}

variable "worker_nodes" {
  default     = 1
  description = "Number of worker nodes"
  type        = number

  validation {
    condition     = var.worker_nodes <= 3
    error_message = "Number of worker nodes must <= 3"
  }
}