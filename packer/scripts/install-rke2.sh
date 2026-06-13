#!/bin/bash
set -xe

# info logs the given argument at info log level.
info() {
    echo "[INFO] " "$@"
}

# warn logs the given argument at warn log level.
warn() {
    echo "[WARN] " "$@" >&2
}

# fatal logs the given argument at fatal log level.
fatal() {
    echo "[ERROR] " "$@" >&2
    exit 1
}

get_installer() {
  info 'Curl-ing RKE2 install script from'
  curl -fsLS https://get.rke2.io -o install.sh
  info 'RKE2 install script downloaded'
}

install_awscli() {
  # Install awscli (used for secrets fetching)
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

install_rke2() {
  info "Installing RKE2"
  # Installing both server and agent services to allow for single AMI
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