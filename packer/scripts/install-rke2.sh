#!/bin/bash
set -xe

info() {
    echo "[INFO] " "$@"
}

warn() {
    echo "[WARN] " "$@" >&2
}

fatal() {
    echo "[ERROR] " "$@" >&2
    exit 1
}

get_installer() {
  info 'Curl-ing RKE2 install script from https://get.rke2.io'
  curl -fsLS https://get.rke2.io -o install.sh
  info 'RKE2 install script downloaded'
}

# awscli is used by cloud-init when the cluster nodes are first booted
# to determine what cluster a node belongs to, whether it should be
# the control plane initializer, join an existing cluster as a control
# plane node, or join as a worker node. It is also used to retrieve
# and distribute the cluster's join token and admin kubeconfig.
install_awscli() {
  rpm -qa | grep aws | xargs zypper remove -y
  info 'Installing AWSCLI'
  curl -fsLS "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
  unzip -q awscliv2.zip
  ./aws/install
  rm -f awscliv2.zip
  rm -rf aws
}

install_hauler() {
  info "Installing Hauler"
  curl -sL https://get.hauler.dev | bash -
}

install_helm() {
  info "Installing Helm"
  curl -sL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 | bash
}

# We install all of the rke2-common, rke2-server, and rke2-agent rpms in order
# to have a single AMI rather than two for control planes and non control planes.
# Most of the files are in the rke2-common package, with only the systemd service
# units in the -server and -agent packages, so all nodes end up with a single
# unused service unit.
install_rke2() {
  info "Installing RKE2"
  INSTALL_RKE2_VERSION=$(curl -sL https://update.rke2.io/v1-release/channels | jq -r '.data[] | select(.id=="stable").latest')
  export INSTALL_RKE2_VERSION
  INSTALL_RKE2_TYPE=server INSTALL_RKE2_METHOD=rpm sh ./install.sh
  # Installer script adds the repo file
  zypper in -y rke2-agent
  rm -f install.sh
  cp /usr/share/rke2/rke2-cis-sysctl.conf /etc/sysctl.d/60-rke2.conf
}

install_yq() {
  info 'Installing yq'
  curl -fsLS https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/local/bin/yq
  chmod 0755 /usr/local/bin/yq
  info 'yq installed'
}

do_install() {
  get_installer
  install_awscli
  install_hauler
  install_helm
  install_rke2
  install_yq
}

{
  info "Beginning download"
  do_install
  info "Ending download"
  info "Complete"
}