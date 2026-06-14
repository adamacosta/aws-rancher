terraform {
  backend "s3" {
    bucket = "aacosta-tfstate"
    key    = "rancher.tfstate"
    region = "us-east-2"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = local.aws_region
  default_tags {
    tags = local.tags
  }
}

data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

data "http" "mykeys" {
  url = "https://github.com/adamacosta.keys"
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

locals {
  account_id          = data.aws_caller_identity.current.account_id
  ami_prefix          = "sles-rke2"
  aws_region          = "us-east-2"
  cidr                = "10.80.0.0/16"
  cluster_name        = "rancher"
  domain              = "rgsdemo.com"
  instance_type       = "m8a.xlarge"
  partition           = data.aws_partition.current.partition
  private_subnets     = ["subnet-0d200b966b653aa6f", "subnet-0ea16bd6d9ee76679", "subnet-02727403a908ee26f"]
  public_subnets      = ["subnet-0d216efdf36457bb0", "subnet-0540c100ed2619ddd", "subnet-0e3eb6d8ec729416e"]
  servers             = 3
  ssh_allowed_cidrs   = ["${trim(data.http.myip.response_body, "\n")}/32"]
  ssh_authorized_keys = split("\n", trim(data.http.mykeys.response_body, "\n"))
  vpc_id              = "vpc-0802dac85e3a9d532"

  tags = {
    Terraform = "true"
    Env       = local.cluster_name
  }
}

data "aws_ami" "server" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["${local.ami_prefix}*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_route53_zone" "domain" {
  name = "${local.domain}."
}

# Control-plane only for Rancher local
module "rke2" {
  source = "git@github.com:ranchergovernment/rke2-aws-tf.git?ref=main"

  lb_subnets = local.public_subnets
  subnets    = local.public_subnets
  vpc_id     = local.vpc_id

  ami                   = data.aws_ami.server.image_id
  cluster_name          = local.cluster_name
  controlplane_internal = false
  download              = false
  instance_type         = local.instance_type
  servers               = local.servers

  enable_autoscaler = false
  enable_ccm        = true

  extra_cloud_config_config = templatefile("${path.module}/files/cloud-config.tftpl", {
    files = [
      {
        content = file("${path.module}/files/audit-policy.yaml")
        path    = "/etc/rancher/rke2/audit-policy.yaml"
      },
      {
        content = file("${path.module}/files/rancher-pss.yaml")
        path    = "/etc/rancher/rke2/rancher-pss.yaml"
      },
      {
        content = file("${path.module}/files/registries.yaml")
        path    = "/etc/rancher/rke2/registries.yaml"
      },
      {
        content = file("${path.module}/files/rke2-cilium-config.yaml")
        path    = "/var/lib/rancher/rke2/server/manifests/rke2-cilium-config.yaml"
      }
    ]
    pubkeys = local.ssh_authorized_keys
  })

  pre_userdata = file("${path.module}/scripts/pre-rke2.sh")
  rke2_config  = file("${path.module}/files/rke2-config.yaml")

  private_dns_name_options = {
    hostname_type = "resource-name"
  }

  suspended_processes = ["AZRebalance", "ReplaceUnhealthy"]
}

resource "aws_security_group_rule" "ssh" {
  cidr_blocks       = local.ssh_allowed_cidrs
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = module.rke2.cluster_data.cluster_sg
  type              = "ingress"
}

resource "aws_security_group_rule" "allow_ping" {
  cidr_blocks       = local.ssh_allowed_cidrs
  from_port         = 8
  to_port           = 0
  protocol          = "icmp"
  security_group_id = module.rke2.cluster_data.cluster_sg
  type              = "ingress"
}

output "rke2" {
  value = module.rke2
}