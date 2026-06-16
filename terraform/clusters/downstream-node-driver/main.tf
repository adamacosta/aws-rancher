terraform {
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

data "rancher2_cloud_credential" "ec2_node_driver" {
  name = "ec2-node-driver"
}

data "aws_region" "current" {}

data "aws_ami" "sles" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["suse-sles-16-0-v*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_vpc" "demo" {
  filter {
    name   = "tag:Name"
    values = ["aacosta-demo"]
  }
}

data "aws_subnet" "public" {
  vpc_id = data.aws_vpc.demo.id

  filter {
    name   = "availability-zone"
    values = ["${local.region}${local.availability_zone}"]
  }

  filter {
    name   = "tag:Name"
    values = ["*-public-*"]
  }
}

locals {
  ami_id               = var.ami_id == null ? data.aws_ami.sles.image_id : var.ami_id
  availability_zone    = var.availability_zone
  aws_ccm_version      = "0.0.11"
  cp_nodes             = var.cp_nodes
  name                 = var.name
  iam_instance_profile = aws_iam_instance_profile.aws_ccm_ebs_csi.name
  instance_type        = var.instance_type
  private_registry     = var.private_registry
  region               = var.region == null ? data.aws_region.current.region : var.region
  registry_secret      = var.registry_secret
  rke2_version         = var.rke2_version
  root_disk_size       = var.root_disk_size
  security_groups      = var.security_groups
  ssh_user             = "ec2-user"
  subnet               = var.subnet == null ? data.aws_subnet.public.id : var.subnet
  volume_type          = var.volume_type
  vpc                  = var.vpc == null ? data.aws_vpc.demo.id : var.vpc
  worker_nodes         = var.worker_nodes
}

# https://ranchermanager.docs.rancher.com/v2.14/reference-guides/cluster-configuration/downstream-cluster-configuration/machine-configuration/amazon-ec2
# https://registry.terraform.io/providers/rancher/rancher2/latest/docs/resources/machine_config_v2#amazonec2_config-1
resource "rancher2_machine_config_v2" "cp" {
  generate_name = local.name

  amazonec2_config {
    ami                        = local.ami_id
    http_protocol_ipv6         = "disabled"
    http_tokens                = "optional"
    iam_instance_profile       = local.iam_instance_profile
    instance_type              = local.instance_type
    region                     = local.region
    root_size                  = local.root_disk_size
    security_group             = local.security_groups
    ssh_user                   = local.ssh_user
    subnet_id                  = local.subnet
    use_ebs_optimized_instance = true
    userdata                   = file("${path.module}/files/cloud-config.yaml")
    volume_type                = local.volume_type
    vpc_id                     = local.vpc
    zone                       = local.availability_zone
  }
}

resource "rancher2_cluster_v2" "ds1" {
  name               = local.name
  default_pod_security_admission_configuration_template_name = "rancher-restricted"
  kubernetes_version = local.rke2_version

  rke_config {
    additional_manifest = templatefile("${path.module}/manifests/addons.yaml.tftpl", {
      aws_ccm_version = local.aws_ccm_version
    })

    chart_values = yamlencode(
      {
        rke2-cilium  = yamldecode(file("${path.module}/manifests/rke2-cilium-values.yaml"))
        rke2-traefik = yamldecode(file("${path.module}/manifests/rke2-traefik-values.yaml"))
      }
    )

    registries {
      configs {
        hostname                = local.private_registry
        auth_config_secret_name = local.registry_secret
      }
      mirrors {
        hostname  = "docker.io"
        endpoints = [local.private_registry]
      }
      mirrors {
        hostname  = "registry.rancher.com"
        endpoints = [local.private_registry]
      }
      mirrors {
        hostname  = "registry.suse.com"
        endpoints = [local.private_registry]
      }
    }

    machine_global_config = file("${path.module}/files/config.yaml")

    machine_pools {
      name                         = "cp"
      cloud_credential_secret_name = data.rancher2_cloud_credential.ec2_node_driver.id
      control_plane_role           = true
      drain_before_delete          = true
      etcd_role                    = true
      quantity                     = local.cp_nodes
      worker_role                  = true

      machine_config {
        kind = rancher2_machine_config_v2.cp.kind
        name = rancher2_machine_config_v2.cp.name
      }
    }

    dynamic "machine_pools" {
      for_each = local.worker_nodes > 0 ? [1] : []
      content {
        name                         = "workers"
        cloud_credential_secret_name = data.rancher2_cloud_credential.ec2_node_driver.id
        drain_before_delete          = true
        quantity                     = local.worker_nodes
        worker_role                  = true

        # For simplicity, we reuse the control plane machine config
        # In reality, you'd probably want a larger instance type for app workloads
        machine_config {
          kind = rancher2_machine_config_v2.cp.kind
          name = rancher2_machine_config_v2.cp.name
        }
      }
    }
  }
}

output "kube_config" {
  sensitive = true
  value     = rancher2_cluster_v2.ds1.kube_config
}