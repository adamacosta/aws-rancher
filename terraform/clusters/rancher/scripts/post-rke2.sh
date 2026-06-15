#!/bin/sh

TOKEN=$(curl -s -X PUT \
  "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
instance_id=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)
asg_name=$(aws autoscaling describe-auto-scaling-instances \
  --instance-ids "$instance_id" \
  --query 'AutoScalingInstances[*].AutoScalingGroupName' \
  --output text)
instances=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-name "$asg_name" \
  --query 'AutoScalingGroups[*].Instances[?HealthStatus==`Healthy`].InstanceId' \
  --output text)
leader=$(echo $instances | tr ' ' '\n' | sort -n | head -n1)

# Only do this on initializer
# Avoiding deploying non-bootstrap charts as addons (files stored in /var/lib/rancher/rke2/server/manifests)
# because this makes it easier to edit them for upgrades. If stored on filesystem, then every copy needs
# to be edited, whereas the HelmChart resource can be edited or patched via the kube-apiserver
[ "$instance_id" = "$leader" ] || exit 0

CARBIDE_USER=$(aws secretsmanager get-secret-value \
  --secret-id "aacosta/carbide-credentials" \
  --no-cli-pager \
  --query 'SecretString' |
  sed -E 's/^"|"$|\\//g' |
  jq -r '.carbide_user')
CARBIDE_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id "aacosta/carbide-credentials" \
  --no-cli-pager \
  --query 'SecretString' |
  sed -E 's/^"|"$|\\//g' |
  jq -r '.carbide_password')

# This will be used by the Helm controller to pull OCI
# charts from the Carbide registry
kubectl create secret docker-registry carbide-registry \
  --namespace kube-system \
  --docker-email="adam.acosta@ranchergovernment.com" \
  --docker-password="$CARBIDE_PASSWORD" \
  --docker-server="registry.ranchercarbide.dev" \
  --docker-username="$CARBIDE_USER"

# This will be used as the registry auth secret for
# downstream clusters to be able to use Carbide
kubectl create secret generic carbide-registry \
  --namespace fleet-default \
  --type=kubernetes.io/basic-auth \
  --from-literal=username="$CARBIDE_USER" \
  --from-literal=password="$CARBIDE_PASSWORD"

# Get a CLI auth token for Carbide's Harbor instance to query the distribution API
CARBIDE_TOKEN=$(curl -sL -u "$CARBIDE_USER:$CARBIDE_PASSWORD" \
  https://registry.ranchercarbide.dev/service/token\?service\=harbor-registry | 
  jq -r '.token')

# Find latest cert-manager and rancher
CERT_MANAGER_VERSION=$(curl -H "Authorization: Bearer $CARBIDE_TOKEN" -sL \
  https://registry.ranchercarbide.dev/v2/charts/cert-manager/tags/list | 
  jq -r '.tags[]' | 
  sort -V | 
  tail -n 1)

RANCHER_VERSION=$(curl -H "Authorization: Bearer $CARBIDE_TOKEN" -sL \
  https://registry.ranchercarbide.dev/v2/carbide-charts/rancher/tags/list | 
  jq -r '.tags[]' | 
  sort -V | 
  tail -n 1)

EXTERNAL_DNS_VERSION=$(curl -sL \
  https://kubernetes-sigs.github.io/external-dns/index.yaml | \
  yq '.entries.external-dns[] | .version' | \
  sort -V |
  tail -n 1)

kubectl apply -f -<<EOF
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: cert-manager
  namespace: kube-system
spec:
  chart: oci://registry.ranchercarbide.dev/charts/cert-manager
  createNamespace: true
  dockerRegistrySecret: 
    name: carbide-registry
  failurePolicy: reinstall
  targetNamespace: cert-manager
  valuesContent: |-
    crds:
      enabled: true
    global:
      imageRegistry: registry.ranchercarbide.dev
    extraArgs:
      - --dns01-recursive-nameservers-only
      - --dns01-recursive-nameservers=8.8.8.8:53,1.1.1.1:53
    podDnsConfig:
    nameservers:
      - 1.1.1.1
  version: $CERT_MANAGER_VERSION
EOF

kubectl apply -f -<<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-issuer
spec:
  acme:
    email: adam.acosta@ranchergovernment.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-issuer-account-key
    solvers:
    - dns01:
        route53:
          hostedZoneID: Z01039472QMMBDSGNF7PD
          region: us-east-2
EOF

kubectl create ns cattle-system

kubectl apply -f -<<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: tls-rancher-ingress
  namespace: cattle-system
spec:
  dnsNames:
    - rancher.rgsdemo.com
    - www.rancher.rgsdemo.com
  duration: 2160h # 90d
  renewBefore: 360h # 15d
  privateKey:
    algorithm: RSA
    encoding: PKCS1
    size: 4096
  isCA: false
  usages:
    - server auth
    - client auth
  subject:
    organizations:
      - rgs-demos
  issuerRef:
    name: letsencrypt-issuer
    kind: ClusterIssuer
  secretName: tls-rancher-ingress
EOF

kubectl create secret generic tls-ca \
  --namespace cattle-system \
  --from-literal=cacerts.pem="$(curl -sL https://letsencrypt.org/certs/isrgrootx1.pem)"

kubectl apply -f -<<EOF
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: external-dns
  namespace: kube-system
spec:
  chart: external-dns
  createNamespace: true
  failurePolicy: reinstall
  repo: https://kubernetes-sigs.github.io/external-dns
  targetNamespace: external-dns
  valuesContent: |-
    provider:
      name: aws
    env:
      - name: AWS_DEFAULT_REGION
        value: us-east-2
  version: $EXTERNAL_DNS_VERSION
EOF

kubectl apply -f -<<EOF
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: rancher
  namespace: kube-system
spec:
  chart: oci://registry.ranchercarbide.dev/carbide-charts/rancher
  createNamespace: true
  dockerRegistrySecret: 
    name: carbide-registry
  failurePolicy: reinstall
  targetNamespace: cattle-system
  valuesContent: |-
    auditLog:
      enabled: true
      level: 2
    hostname: rancher.rgsdemo.com
    ingress:
      tls:
        source: secret
    privateCA: true
  version: $RANCHER_VERSION
EOF