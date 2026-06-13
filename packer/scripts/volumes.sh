#!/bin/bash

set -xe

SIZE="${VARLIB_VOL_SIZE:-100}G"

# Create and format all disks - identify which disk to use by its size
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