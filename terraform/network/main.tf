terraform {
  backend "s3" {
    bucket = "aacosta-tfstate"
    key    = "aacosta-demo.tfstate"
    region = "us-east-2"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {}

data "aws_availability_zones" "available" {}

data "aws_region" "current" {}

locals {
  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  cidr            = var.cidr
  domain          = var.domain
  name            = var.name
  region          = var.region == null ? data.aws_region.current.region : var.region
  vpn_client_cidr = var.vpn_client_cidr

  tags = {
    Terraform = "true"
    Env       = local.name
  }
}

data "aws_iam_saml_provider" "sso" {
  arn = "arn:aws:iam::045660478867:saml-provider/AWSSSO_ca43816631aac05f_DO_NOT_DELETE"
}

data "aws_route53_zone" "domain" {
  name = "${local.domain}."
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = local.name
  cidr = local.cidr

  azs             = local.azs
  intra_subnets   = [for k, v in slice(local.azs, 0, 2) : cidrsubnet(local.cidr, 3, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.cidr, 3, k + 2)]
  private_subnets = [for k, v in local.azs : cidrsubnet(local.cidr, 3, k + 5)]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  # EC2s launched into a public subnet that do not have a public IP
  # address will not be able to access the Internet because public subnets
  # do not get NAT gateways
  map_public_ip_on_launch    = true
  manage_default_network_acl = true

  public_subnet_tags  = merge({ "kubernetes.io/role/elb" = "1" }, local.tags)
  private_subnet_tags = merge({ "kubernetes.io/role/internal-elb" = "1" }, local.tags)

  tags = local.tags
}

# resource "aws_acm_certificate" "vpn" {
#   domain_name       = "vpn.${local.domain}"
#   validation_method = "DNS"
# }

# resource "aws_route53_record" "vpn_certificate_validation" {
#   for_each = {
#     for dvo in aws_acm_certificate.vpn.domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#   }

#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = data.aws_route53_zone.domain.zone_id
# }

# resource "aws_iam_saml_provider" "vpn" {
#   name                   = "aws-client-vpn"
#   saml_metadata_document = data.aws_iam_saml_provider.sso.saml_metadata_document
# }

# resource "aws_security_group" "vpn" {
#   name        = "${local.name}-vpn-sg"
#   description = "Allow VPN access"
#   vpc_id      = module.vpc.vpc_id

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = [local.cidr]
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_ec2_client_vpn_endpoint" "vpn" {
#   description            = "${local.name}-clientvpn"
#   server_certificate_arn = aws_acm_certificate.vpn.arn
#   client_cidr_block      = local.vpn_client_cidr
#   dns_servers            = [cidrhost(local.cidr, 2)]
#   security_group_ids     = [aws_security_group.vpn.id]
#   self_service_portal    = "disabled"
#   split_tunnel           = true
#   vpc_id                 = module.vpc.vpc_id

#   authentication_options {
#     type                       = "certificate-authentication"
#     root_certificate_chain_arn = aws_acm_certificate.vpn.arn
#   }

#   connection_log_options {
#     enabled = false
#   }

#   tags = {
#     Name = "${local.name}"
#   }
# }

# resource "aws_ec2_client_vpn_network_association" "vpn" {
#   for_each = tomap({
#     for i, id in module.vpc.private_subnets : i => id
#   })

#   client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
#   subnet_id              = each.value
# }

# resource "aws_ec2_client_vpn_authorization_rule" "vpn" {
#   client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
#   target_network_cidr    = local.cidr
#   authorize_all_groups   = true
# }

output "vpc" {
  value = module.vpc
}