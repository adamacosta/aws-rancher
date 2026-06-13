terraform {
  backend "s3" {
    bucket = "aacosta-tfstate"
    key    = "server-test.tfstate"
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

locals {
  ami_owners          = ["self"]
  ami_prefix          = "sles-rke2"
  aws_region          = "us-east-2"
  domain              = "rgsdemo.com"
  instance_type       = var.instance_type
  server_name         = "server-test"
  servers             = var.servers
  ssh_allowed_cidr    = "${trim(data.http.myip.response_body, "\n")}/32"
  ssh_authorized_keys = split("\n", trim(data.http.mykeys.response_body, "\n"))
  subnet              = "subnet-0d216efdf36457bb0"
  vpc_id              = "vpc-0802dac85e3a9d532"

  tags = {
    Terraform = "true"
    Name      = local.server_name
  }
}

data "aws_ami" "server" {
  most_recent = true
  owners      = local.ami_owners

  filter {
    name   = "name"
    values = ["${local.ami_prefix}*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

## Security group
# allow inbound from my IP only, all outbound
resource "aws_security_group" "server" {
  name        = local.server_name
  description = "Allow inbound traffic for demo and all outbound traffic"
  vpc_id      = local.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "allow_self" {
  security_group_id            = aws_security_group.server.id
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.server.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.server.id
  cidr_ipv4         = local.ssh_allowed_cidr
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_ping" {
  security_group_id = aws_security_group.server.id
  cidr_ipv4         = local.ssh_allowed_cidr
  from_port         = 8
  ip_protocol       = "icmp"
  to_port           = 0
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.server.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

## IAM
# EC2 instance profile with required API permissions
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "server" {
  name               = local.server_name
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_instance_profile" "server" {
  name = local.server_name
  role = aws_iam_role.server.name
}

## Server
# EC2 with attached storage
data "cloudinit_config" "server" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"

    content = templatefile("${path.module}/files/cloud-config.tftpl", {
      pubkeys = local.ssh_authorized_keys
    })
  }
}

resource "aws_instance" "server" {
  count = local.servers

  ami                    = data.aws_ami.server.id
  iam_instance_profile   = aws_iam_instance_profile.server.name
  instance_type          = local.instance_type
  user_data_base64       = data.cloudinit_config.server.rendered
  subnet_id              = local.subnet
  vpc_security_group_ids = [aws_security_group.server.id]

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 3
  }

  tags = {
    Name = "server-${count.index}"
  }
}

output "server_ip" {
  value = aws_instance.server[*].public_ip
}