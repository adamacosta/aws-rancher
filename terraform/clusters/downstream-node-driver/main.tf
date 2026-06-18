terraform {
  backend "s3" {
    bucket = "aacosta-tfstate"
    key    = "rancher-ds.tfstate"
    region = "us-east-2"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    rancher2 = {
      source  = "rancher/rancher2"
      version = "~> 14.1"
    }
  }
}

provider "rancher2" {
  api_url = "https://rancher.rgsdemo.com"
}

locals {
  aws_ccm_version      = "0.0.11"
  iam_instance_profile = aws_iam_instance_profile.aws_ccm_ebs_csi.name
}

module "ds_app_prod" {
  source = "./modules/cluster"

  name = "ds-app-prod"

  aws_ccm_version      = local.aws_ccm_version
  cp_nodes             = 3
  iam_instance_profile = local.iam_instance_profile
  rke2_version         = "v1.35.4+rke2r1"
  worker_nodes         = 1

  labels = {
    env  = "prod"
    type = "app"
  }
}

module "ds_app_dev" {
  source = "./modules/cluster"

  name = "ds-app-dev"

  aws_ccm_version      = local.aws_ccm_version
  cp_nodes             = 3
  iam_instance_profile = local.iam_instance_profile
  rke2_version         = "v1.35.4+rke2r1"
  worker_nodes         = 1

  labels = {
    env  = "dev"
    type = "app"
  }
}

output "ds_app_prod" {
  sensitive = true
  value     = module.ds_app_prod
}

output "ds_app_dev" {
  sensitive = true
  value     = module.ds_app_dev
}