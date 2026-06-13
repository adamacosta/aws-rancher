packer {
  required_plugins {
    amazon = {
      version = "~> 1.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

locals {
  ami_name                = "sles-rke2"
  root_vol_size           = "30"
  ssh_key                 = "~/.ssh/id_ed25519"
  ssh_user                = "rancher"
  varlib_vol_size         = "100"
  vol_delete_on_terminate = true
  vol_encrypt             = true
  vol_type                = "gp3"
}

source "amazon-ebs" "sles_base" {
  ami_name                    = "${local.ami_name}-{{ timestamp }}"
  ami_virtualization_type     = "hvm"
  associate_public_ip_address = true
  ebs_optimized               = true
  iam_instance_profile        = "packer-carbide-credentials"
  imds_support                = "v2.0"
  instance_type               = var.instance_type
  region                      = var.aws_region
  skip_create_ami             = false
  ssh_private_key_file        = local.ssh_key
  ssh_username                = local.ssh_user
  subnet_id                   = var.subnet_id
  vpc_id                      = var.vpc_id

  tags = {
    Name         = local.ami_name
    SLES_VERSION = var.sles_version
  }

  user_data = templatefile("${path.root}/files/cloud-config.tftpl", {
    ssh_pubkey = file("${local.ssh_key}.pub")
    ssh_user   = local.ssh_user
  })

  # /
  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    delete_on_termination = local.vol_delete_on_terminate
    encrypted             = local.vol_encrypt
    volume_size           = local.root_vol_size
    volume_type           = local.vol_type
  }

  # /var/lib/kubelet /var/lib/rancher
  launch_block_device_mappings {
    device_name           = "/dev/sda2"
    delete_on_termination = local.vol_delete_on_terminate
    encrypted             = local.vol_encrypt
    volume_size           = local.varlib_vol_size
    volume_type           = local.vol_type
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # suse-sles-MAJ-MIN-vYYYYMMDD is the prefix for subscribed hosts
  # suse-sles-MAJ-MIN-byos-vYYYYMMDD is used for bring your own subscription
  # We specify the -v* to avoid using byos
  # Equivalent to
  # aws ec2 describe-images \
  #   --owners "amazon" \
  #   --filters "Name=name,Values=suse-sles-16-0-v*" "Name=architecture,Values=x86_64" \
  #   --query "sort_by(Images, &CreationDate)[-1].ImageId" \
  #   --no-cli-pager \
  #   --output text
  source_ami_filter {
    filters = {
      name         = "suse-sles-${replace(var.sles_version, ".", "-")}-v*"
      architecture = "x86_64"
    }
    most_recent = true
    owners      = ["amazon"]
  }
}

build {
  name = "sles-rke2"
  sources = [
    "source.amazon-ebs.sles_base"
  ]

  provisioner "shell" {
    inline = ["sudo cloud-init status --wait"]
  }

  # Expecting kernel update from cloud-init
  provisioner "shell" {
    inline            = ["sudo systemctl reboot"]
    expect_disconnect = true
    pause_after       = "30s"
  }

  provisioner "shell" {
    env = {
      VARLIB_VOL_SIZE = local.varlib_vol_size
    }
    execute_command = "sudo env {{ .Vars }} {{ .Path }}"
    scripts = [
      "${path.root}/scripts/volumes.sh",
      "${path.root}/scripts/install-rke2.sh",
      "${path.root}/scripts/seed-images.sh",
      "${path.root}/scripts/fix-cloudinit.sh"
    ]
  }

  # See notes/machine-id.md for why we need to set a keymap
  provisioner "shell" {
    inline = [
      "sudo localectl set-keymap us",
      "sudo journalctl --flush",
      "sudo journalctl --rotate",
      "sudo journalctl --vacuum-time=1s",
      "cat /dev/null | sudo tee /var/log/audit/audit.log",
      "cat /dev/null | sudo tee /var/log/zypper.log",
      "cat /dev/null | sudo tee /var/log/alternatives.log",
      "sudo cloud-init clean --logs --machine-id --seed",
      "sudo rm -f /var/lib/systemd/random-seed",
      "sudo rm -f /etc/hostname"
    ]
  }
}