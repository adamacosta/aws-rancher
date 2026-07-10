data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

data "http" "mykeys" {
  url = "https://github.com/adamacosta.keys"
}

locals {
  allowed_cidr        = "${trim(data.http.myip.response_body, "\n")}/32"
  ami_owners          = ["amazon"]
  ami_prefix          = "suse-sles-${replace(var.sles_version, ".", "-sp")}-v*"
  aws_region          = "us-east-2"
  instance_type       = var.bastion_instance_type
  ssh_authorized_keys = split("\n", trim(data.http.mykeys.response_body, "\n"))
  private_subnet      = module.vpc.private_subnets[0]
  public_subnet       = module.vpc.public_subnets[0]
  vpc_id              = module.vpc.vpc_id
}

data "aws_ami" "bastion" {
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
resource "aws_security_group" "bastion" {
  name        = "${local.name}-bastion"
  description = "Allow inbound traffic for demo and all outbound traffic"
  vpc_id      = local.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "allow_self" {
  security_group_id            = aws_security_group.bastion.id
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.bastion.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.bastion.id
  cidr_ipv4         = local.allowed_cidr
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "onboarder_kasm_tcp" {
  security_group_id = aws_security_group.bastion.id

  from_port   = 8443
  to_port     = 8449
  ip_protocol = "tcp"
  cidr_ipv4   = local.allowed_cidr
}

resource "aws_vpc_security_group_ingress_rule" "onboarder_kasm_udp" {
  security_group_id = aws_security_group.bastion.id

  from_port   = 8443
  to_port     = 8449
  ip_protocol = "udp"
  cidr_ipv4   = local.allowed_cidr
}

resource "aws_vpc_security_group_ingress_rule" "allow_ping" {
  security_group_id = aws_security_group.bastion.id
  cidr_ipv4         = local.allowed_cidr
  from_port         = 8
  ip_protocol       = "icmp"
  to_port           = 0
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.bastion.id
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

resource "aws_iam_role" "bastion" {
  name               = "${local.name}-bastion"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${local.name}-bastion"
  role = aws_iam_role.bastion.name
}

resource "aws_iam_role_policy_attachment" "bastion_admin" {
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role       = aws_iam_role.bastion.name
}

## Server
# EC2 with attached storage
data "cloudinit_config" "bastion" {
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

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.bastion.id
  iam_instance_profile   = aws_iam_instance_profile.bastion.name
  instance_type          = local.instance_type
  user_data_base64       = data.cloudinit_config.bastion.rendered
  subnet_id              = local.public_subnet
  vpc_security_group_ids = [aws_security_group.bastion.id]

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 3
  }

  root_block_device {
    volume_size = 1024
    volume_type = "gp3"
  }

  tags = {
    Name = "${local.name}-bastion"
  }
}

resource "aws_network_interface" "bastion" {
  subnet_id       = module.vpc.private_subnets[0]
  security_groups = [aws_security_group.bastion.id]

  private_ips = [cidrhost(module.vpc.private_subnets_cidr_blocks[0], 10)]
}

resource "aws_network_interface_attachment" "bastion" {
  instance_id          = aws_instance.bastion.id
  network_interface_id = aws_network_interface.bastion.id
  device_index         = 1
}

resource "aws_eip" "bastion_ip" {
  network_interface = aws_instance.bastion.primary_network_interface_id
  domain            = "vpc"

  tags = {
    Name = "${local.name}-bastion"
  }
}

output "server_ip" {
  value = aws_eip.bastion_ip.address
}