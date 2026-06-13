#!/bin/bash
set -e

# Stored secret looks like:
# "{\"carbide_user\":\"$CARBIDE_USER\",\"carbide_password\":\"$CARBIDE_PASSWORD\"}"
CARBIDE_USER=$(aws secretsmanager get-secret-value --secret-id "aacosta/carbide-credentials" --no-cli-pager --query "SecretString" | sed -E 's/^"|"$|\\//g' | jq -r '.carbide_user')
CARBIDE_PASSWORD=$(aws secretsmanager get-secret-value --secret-id "aacosta/carbide-credentials" --no-cli-pager --query "SecretString" | sed -E 's/^"|"$|\\//g' | jq -r '.carbide_password')
hauler login registry.ranchercarbide.dev -u "$CARBIDE_USER" -p "$CARBIDE_PASSWORD"

# Setting here to avoid printing out the credentials to build log
set -x

AWS_CCM_REPO="https://kubernetes.github.io/cloud-provider-aws"

# Expecting to match something like v1.35.0+rke2r1
RKE2_VERSION=$(rke2 --version | grep -Eo 'v1\.[0-9]{2}\.[0-9]+\+[a-z0-9]+')
RKE2_MAJ_MIN=$(echo "$RKE2_VERSION" | cut -d '.' -f1,2)

helm repo add aws-cloud-controller-manager "$AWS_CCM_REPO"
helm repo update

cat << EOF >> hauler-manifest.yaml
apiVersion: content.hauler.cattle.io/v1
kind: Images
metadata:
  name: hauler-cluster-images
spec:
  images:
$(curl -sL "https://github.com/rancher/rke2/releases/download/$RKE2_VERSION/rke2-images-core.linux-amd64.txt" | sed 's/^/    - name: /' | sed 's/docker\.io/registry\.ranchercarbide\.dev/')
$(curl -sL "https://github.com/rancher/rke2/releases/download/$RKE2_VERSION/rke2-images-cilium.linux-amd64.txt" | sed 's/^/    - name: /' | sed 's/docker\.io/registry\.ranchercarbide\.dev/')
$(curl -sL "https://github.com/rancher/rke2/releases/download/$RKE2_VERSION/rke2-images-traefik.linux-amd64.txt" | sed 's/^/    - name: /' | sed 's/docker\.io/registry\.ranchercarbide\.dev/')
EOF

export RKE2_MAJ_MIN
AWS_CCM_VERSION=$(helm search repo -l aws-cloud-controller-manager/aws-cloud-controller-manager -ojson | jq -r '.[] | select(.app_version | startswith(env.RKE2_MAJ_MIN)).version')

cat <<EOF >> hauler-manifest.yaml
$(helm template aws-cloud-controller-manager aws-cloud-controller-manager/aws-cloud-controller-manager --version "$AWS_CCM_VERSION" | yq '.spec.template.spec.containers[] | .image' | sed 's/^/    - name: /')
EOF

hauler store sync --filename hauler-manifest.yaml --platform linux/amd64

mkdir -p /var/lib/rancher/rke2/agent/images
hauler store save --containerd --filename /var/lib/rancher/rke2/agent/images/seed.tar.zst

rm -f hauler-manifest.yaml
rm -rf store
hauler logout registry.ranchercarbide.dev

# Doing here because there is no obvious way to automate finding version in cloud-init write_files
mkdir -p /var/lib/rancher/rke2/server/manifests
cat <<EOF > /var/lib/rancher/rke2/server/manifests/aws-ccm.yaml
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: aws-cloud-controller-manager
  namespace: kube-system
spec:
  bootstrap: true
  chart: aws-cloud-controller-manager
  failurePolicy: reinstall
  repo: $AWS_CCM_REPO
  targetNamespace: kube-system
  valuesContent: |-
    args:
      - --v=2
      - --cloud-provider=aws
      - --allocate-node-cidrs=false
      - --configure-cloud-routes=false
    nodeSelector:
      node-role.kubernetes.io/control-plane: "true"
  version: $AWS_CCM_VERSION
EOF