#!/bin/bash

# This script deserves some expanded explanation.
#
# STIG controls for Linux distros often require separate disks or partitions for
# important parts of the Linux filesystem hierarchy standard that may fill up
# to avoid impacts to logging, putting /var, /var/log, and /var/log/audit
# on their own partitions, along with /home and sometimes others.
#
# On SL Micro and SLES 16+, this is not necessary because logical separation
# is achieved via btrfs subvolumes, but we are still putting /var/lib/rancher
# and /var/lib/kubelet on their own partitions, in part because they are
# likely to be the only locations accumulating a lot of data on a Kubernetes
# node, but also because containerd is using overlayfs as the default snapshotter
# and that works better when the underlying filesystem is ext4 rather than btrfs,
# which will also be doing its own snapshotting.
#
# Ryan McDaniel and Mike D'Amato, possibly with help from Adam Leiner, wrote the
# original version of a script for automating this via cloud-init during
# first boot by passing in as user-data with built-in knowledge of the expected
# EBS volume sizes. Since full STIG hardening can be time-consuming, I
# advocated for moving all of this pre-hardening and disk partioning into
# the AMI instead, saving about 20 minutes per first boot when installing rke2
# and when refreshing nodes to pick up OS patches.
#
# If you know the volumes will be using gp3, which presents to the instance
# over nvme rather than SATA, it is possible to use nvme-cli to detect the
# EBS volume ID and tags embedded in the vendor data for the disk, which is
# probably more robust than this technique, since this requires every disk
# to be uniquely sized, but this method is simpler and more general.

set -xe

SIZE="${VARLIB_VOL_SIZE:-100}G"

# /var/lib/kubelet /var/lib/rancher
VAR_LIB="/dev/$(lsblk | grep "$SIZE" | awk '{print $1}')"
parted -s "$VAR_LIB" mklabel gpt
parted -s -a optimal "$VAR_LIB" mkpart "p.varlibkubelet" ext4 1MiB 20%
parted -s -a optimal "$VAR_LIB" mkpart "p.varlibrancher" ext4 20% 100%
mkfs.ext4 -L "VARLIBKUBELET" "${VAR_LIB}p1"
mkfs.ext4 -L "VARLIBRANCHER" "${VAR_LIB}p2"

mkdir -p /var/lib/kubelet
mkdir -p /var/lib/rancher

# Initial fstab
echo "LABEL=VARLIBKUBELET /var/lib/kubelet ext4 defaults 0 2" | tee -a /etc/fstab
echo "LABEL=VARLIBRANCHER /var/lib/rancher ext4 defaults 0 2" | tee -a /etc/fstab

mount -a