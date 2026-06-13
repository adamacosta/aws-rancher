#!/bin/sh

CARBIDE_USER=$(aws secretsmanager get-secret-value --secret-id "aacosta/carbide-credentials" --no-cli-pager --query 'SecretString' | sed -E 's/^"|"$|\\//g' | jq -r '.carbide_user')
CARBIDE_PASSWORD=$(aws secretsmanager get-secret-value --secret-id "aacosta/carbide-credentials" --no-cli-pager --query 'SecretString' | sed -E 's/^"|"$|\\//g' | jq -r '.carbide_password')

user=$CARBIDE_USER yq -i \
  '.configs."registry.ranchercarbide.dev".auth.username = strenv(user)' \
  /etc/rancher/rke2/registries.yaml
password=$CARBIDE_PASSWORD yq -i \
  '.configs."registry.ranchercarbide.dev".auth.password = strenv(password)' \
  /etc/rancher/rke2/registries.yaml

cat <<EOF >> /root/.bashrc
export PATH="$PATH:/var/lib/rancher/rke2/bin"
export KUBECONFIG="/etc/rancher/rke2/rke2.yaml"
export CRI_CONFIG_FILE="/var/lib/rancher/rke2/agent/etc/crictl.yaml"
export CONTAINERD_ADDRESS="/run/k3s/containerd/containerd.sock"
command -v kubectl >/dev/null && . <(kubectl completion bash)
EOF