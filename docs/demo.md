# Demo

## Auth

<https://rancher.rgsdemo.com>

Navigate to auth tab to show Cognito integration after logging in. Explain SSO.

## Dashboard

Explain `local` cluster.

Go through how to find resources. Show pod logs. Scale a deployment up and back down from the UI. Show the yaml views. Download a kubeconfig for the admin user. Show the "explain resource" button and how it is equivalent to command line `kubectl explain`, which gives you the documentation for the protobuf spec defining the API resource.

### Cluster Management

Explain the four types of clusters and their respective lifecycle management capabilities:
- Registered
  - Complete cluster created outside of Rancher with `cattle-cluster-agent` installed onto it afterward
  - Rancher provides visibility and resource management
  - May install and management application lifecycles
  - May optionally manage Kubernetes upgrades if Kubernetes is RKE2 or k3s
- Custom
  - Machine(s) created outside of Rancher
  - Rancher installs RKE2 or k3s via `rancher-system-agent` and assumes full lifecycle management of Kubernetes
- Node driver
  - Rancher provisions machines via cloud provider API
  - Installation and full lifecycle management of Kubernetes and the machines themselves
- Cluster driver
  - Provisions a hosted Kubernetes cluster via cloud provider API
  - Full lifecycle management

Show ssh options:
  - Create an ssh shell in Rancher
  - Download the key material

Show the cloud credential for AWS, created especially for Rancher Government to allow use of EC2 instance profile rather than using long-lived static access keys.

Scale up a worker node pool in a node driver cluster.

Upgrade RKE2 on a node driver cluster.

Explain the `system-upgrade-controller` and show what a `Plan` is.

Show the cluster configuration and explain all of the hardening to comply with STIG and CIS benchmark.

### Rancher Catalog

Install the `compliance-operator` and run a CIS scan. Explain the few `Warn` findings I didn't implement for a demo and why.

### RBAC

Login as the developer user and show the limited view. No `local` cluster should show up. If this user attempts to create anything in the prod cluster, it should fail. They should be able to create resources in the dev cluster. Show all of this via the `shell` pod that can be launched directly in the Rancher UI.

### Continuous Delivery

Show the `GitRepo` and `Bundle` resources in the UI and how they correspond to what is in the Git repo on Github. Explain how a private repo is authenticated to. Upgrade `cert-manager` and show it reconcile.

Explain target customizations and show the `bookinfo` application with a `Gateway` and public DNS record in the prod cluster.

### Terraform Provider

Deploy a new dev cluster and `fleet` should automatically install the same applications as the existing dev cluster.

## RKE2

Login over ssh to a Rancher cluster node and show around how it is installed onto RKE2.

Discuss the Carbide secure software factory and container registry. Show that our images come from Carbide.

```console
# crictl images
IMAGE                                                                       TAG                                                           IMAGE ID            SIZE
docker.io/rancher/fleet                                                     v0.15.2                                                       0de8b2a4a95ff       110MB
registry.ranchercarbide.dev/rancher/fleet                                   v0.15.2                                                       0de8b2a4a95ff       110MB
docker.io/rancher/machine                                                   v0.15.0-rancher142                                            cf76dd14e4aff       84.3MB
docker.io/rancher/mirrored-bci-micro                                        15.6.24.2                                                     1de2dfa4ac9e6       10.4MB
docker.io/rancher/rancher-agent                                             v2.14.2                                                       84f8352ff0488       655MB
docker.io/rancher/rancher                                                   v2.14.2                                                       bc12f93371088       998MB
docker.io/rancher/shell                                                     v0.7.0                                                        2496eed93f6d6       112MB
registry.ranchercarbide.dev/rancher/shell                                   v0.7.0                                                        2496eed93f6d6       112MB
docker.io/rancher/system-upgrade-controller                                 v0.19.1                                                       f7fb7c97cfff7       14.6MB
registry.k8s.io/provider-aws/cloud-controller-manager                       v1.35.0                                                       9b00c547bac32       28.4MB
registry.ranchercarbide.dev/provider-aws/cloud-controller-manager           v1.35.0                                                       9b00c547bac32       28.4MB
registry.ranchercarbide.dev/rancher/fleet-agent                             v0.15.2                                                       38e59ab31ec5b       26.6MB
registry.ranchercarbide.dev/rancher/hardened-addon-resizer                  1.8.23-build20260511                                          2bf59a3eac32a       14.4MB
registry.ranchercarbide.dev/rancher/hardened-cluster-autoscaler             v1.10.3-build20260511                                         d038a39229938       14.2MB
registry.ranchercarbide.dev/rancher/hardened-cni-plugins                    v1.9.1-build20260511                                          0672b5187ef73       50.1MB
registry.ranchercarbide.dev/rancher/hardened-coredns                        v1.14.3-build20260511                                         99261173a7d77       30.3MB
registry.ranchercarbide.dev/rancher/hardened-dns-node-cache                 1.26.8-build20260511                                          905a6441a5a11       24.5MB
registry.ranchercarbide.dev/rancher/hardened-etcd                           v3.6.7-k3s1-build20260512                                     049333f035660       18MB
registry.ranchercarbide.dev/rancher/hardened-k8s-metrics-server             v0.8.1-build20260513                                          34a12bffadcbf       21.9MB
registry.ranchercarbide.dev/rancher/hardened-kubernetes                     v1.35.5-rke2r2-build20260521                                  0c2c3b9d8b6fe       201MB
registry.ranchercarbide.dev/rancher/hardened-snapshot-controller            v8.5.0-build20260513                                          a044490a79f4a       38.6MB
registry.ranchercarbide.dev/rancher/hardened-traefik                        v3.6.16-build20260512                                         ba5a595169a7c       50.2MB
registry.ranchercarbide.dev/rancher/klipper-helm                            v0.10.0-build20260513                                         627854a8d2956       61.2MB
registry.ranchercarbide.dev/rancher/klipper-lb                              v0.4.17                                                       a2eee18230286       5.28MB
registry.ranchercarbide.dev/rancher/kube-webhook-certgen                    v1.14.5-hardened2                                             1452f03064dc8       26.5MB
registry.ranchercarbide.dev/rancher/mirrored-cilium-certgen                 v0.4.1                                                        af917567126be       13MB
registry.ranchercarbide.dev/rancher/mirrored-cilium-cilium-envoy            v1.36.6-1776000132-2437d2edeaf4d9b56ef279bd0d71127440c067aa   e3d35f67c21dc       72.1MB
registry.ranchercarbide.dev/rancher/mirrored-cilium-cilium                  v1.19.3                                                       0bf1cfc954f1a       260MB
registry.ranchercarbide.dev/rancher/mirrored-cilium-clustermesh-apiserver   v1.19.3                                                       2f8facb20500d       36.6MB
registry.ranchercarbide.dev/rancher/mirrored-cilium-hubble-relay            v1.19.3                                                       eb58f8a64d5ee       23.8MB
registry.ranchercarbide.dev/rancher/mirrored-cilium-hubble-ui-backend       v0.13.3                                                       4b2b7e0cc51a9       20.7MB
registry.ranchercarbide.dev/rancher/mirrored-cilium-hubble-ui               v0.13.3                                                       19fbc77f3f01d       11.5MB
registry.ranchercarbide.dev/rancher/mirrored-cilium-operator-aws            v1.19.3                                                       3a57b43bbad6e       39.6MB
registry.ranchercarbide.dev/rancher/mirrored-cilium-operator-azure          v1.19.3                                                       c251db369cd83       34.6MB
registry.ranchercarbide.dev/rancher/mirrored-cilium-operator-generic        v1.19.3                                                       1c47aa60d9003       33.5MB
registry.ranchercarbide.dev/rancher/mirrored-pause                          3.6                                                           bb03d7b010b58       300kB
registry.ranchercarbide.dev/rancher/nginx-ingress-controller                v1.14.5-hardened2                                             47329b9bd00e8       274MB
registry.ranchercarbide.dev/rancher/rancher-webhook                         v0.10.6                                                       7998bfd0f2098       22.3MB
registry.ranchercarbide.dev/rancher/rke2-cloud-provider                     v1.35.4-0.20260415195656-e51c0636351d-build20260415           14c428d0e9244       20.9MB
registry.ranchercarbide.dev/rancher/rke2-runtime                            v1.35.5-rke2r2                                                3729785e2f271       101MB
```

Explain `containerd` registry mirrors and why some of these show up as coming from Carbide registry, but still come from there because of the mirror.

```console
# yq '.mirrors' /etc/rancher/rke2/registries.yaml
docker.io:
  endpoint:
    - "https://registry.ranchercarbide.dev"
registry.rancher.com:
  endpoint:
    - "https://registry.ranchercarbide.dev"
registry.suse.com:
  endpoint:
    - "https://registry.ranchercarbide.dev"
```

Everything that shows up as being from Carbide is because it was pre-loaded into `containerd` local content store rather than pulled.

```console
# zstd -cd /var/lib/rancher/rke2/agent/images/seed.tar.zst | tar -xO -f - index.json | jq -r '.manifests[] | .annotations."io.containerd.image.name"'
registry.ranchercarbide.dev/rancher/klipper-lb:v0.4.17
registry.ranchercarbide.dev/rancher/mirrored-pause:3.6
registry.ranchercarbide.dev/rancher/hardened-cni-plugins:v1.9.1-build20260511
registry.ranchercarbide.dev/rancher/hardened-addon-resizer:1.8.23-build20260511
registry.ranchercarbide.dev/rancher/mirrored-cilium-operator-generic:v1.19.3
registry.ranchercarbide.dev/rancher/mirrored-cilium-cilium-envoy:v1.36.6-1776000132-2437d2edeaf4d9b56ef279bd0d71127440c067aa
registry.ranchercarbide.dev/rancher/mirrored-cilium-hubble-relay:v1.19.3
registry.ranchercarbide.dev/rancher/klipper-helm:v0.10.0-build20260513
registry.ranchercarbide.dev/rancher/hardened-etcd:v3.6.7-k3s1-build20260512
registry.ranchercarbide.dev/rancher/mirrored-cilium-operator-azure:v1.19.3
registry.ranchercarbide.dev/rancher/hardened-cluster-autoscaler:v1.10.3-build20260511
registry.ranchercarbide.dev/rancher/mirrored-cilium-hubble-ui:v0.13.3
registry.ranchercarbide.dev/rancher/rke2-runtime:v1.35.5-rke2r2
registry.ranchercarbide.dev/rancher/mirrored-cilium-operator-aws:v1.19.3
registry.ranchercarbide.dev/rancher/mirrored-cilium-hubble-ui-backend:v0.13.3
registry.ranchercarbide.dev/rancher/hardened-dns-node-cache:1.26.8-build20260511
registry.ranchercarbide.dev/rancher/mirrored-cilium-cilium:v1.19.3
registry.ranchercarbide.dev/rancher/kube-webhook-certgen:v1.14.5-hardened2
registry.k8s.io/provider-aws/cloud-controller-manager:v1.35.0
registry.ranchercarbide.dev/rancher/nginx-ingress-controller:v1.14.5-hardened2
registry.ranchercarbide.dev/rancher/hardened-coredns:v1.14.3-build20260511
registry.ranchercarbide.dev/rancher/rke2-cloud-provider:v1.35.4-0.20260415195656-e51c0636351d-build20260415
registry.ranchercarbide.dev/rancher/hardened-snapshot-controller:v8.5.0-build20260513
registry.ranchercarbide.dev/rancher/mirrored-cilium-clustermesh-apiserver:v1.19.3
registry.ranchercarbide.dev/rancher/hardened-traefik:v3.6.16-build20260512
registry.ranchercarbide.dev/rancher/hardened-k8s-metrics-server:v0.8.1-build20260513
registry.ranchercarbide.dev/rancher/hardened-kubernetes:v1.35.5-rke2r2-build20260521
registry.ranchercarbide.dev/rancher/mirrored-cilium-certgen:v0.4.1
registry.ranchercarbide.dev/rancher/hardened-addon-resizer:1.8.23-build20260511
registry.ranchercarbide.dev/rancher/mirrored-cilium-operator-generic:v1.19.3
registry.ranchercarbide.dev/rancher/mirrored-cilium-operator-aws:v1.19.3
registry.ranchercarbide.dev/rancher/mirrored-cilium-cilium:v1.19.3
registry.ranchercarbide.dev/rancher/hardened-cluster-autoscaler:v1.10.3-build20260511
registry.ranchercarbide.dev/rancher/hardened-addon-resizer:1.8.23-build20260511
registry.ranchercarbide.dev/rancher/hardened-coredns:v1.14.3-build20260511
registry.ranchercarbide.dev/rancher/mirrored-cilium-clustermesh-apiserver:v1.19.3
registry.ranchercarbide.dev/rancher/mirrored-cilium-cilium:v1.19.3
registry.ranchercarbide.dev/rancher/hardened-dns-node-cache:1.26.8-build20260511
registry.ranchercarbide.dev/rancher/mirrored-cilium-hubble-relay:v1.19.3
registry.ranchercarbide.dev/rancher/rke2-cloud-provider:v1.35.4-0.20260415195656-e51c0636351d-build20260415
registry.ranchercarbide.dev/rancher/hardened-etcd:v3.6.7-k3s1-build20260512
registry.ranchercarbide.dev/rancher/hardened-traefik:v3.6.16-build20260512
registry.ranchercarbide.dev/rancher/mirrored-cilium-operator-generic:v1.19.3
registry.ranchercarbide.dev/rancher/rke2-runtime:v1.35.5-rke2r2
registry.ranchercarbide.dev/rancher/mirrored-cilium-operator-azure:v1.19.3
registry.ranchercarbide.dev/rancher/mirrored-cilium-cilium-envoy:v1.36.6-1776000132-2437d2edeaf4d9b56ef279bd0d71127440c067aa
registry.ranchercarbide.dev/rancher/klipper-lb:v0.4.17
registry.ranchercarbide.dev/rancher/mirrored-cilium-cilium-envoy:v1.36.6-1776000132-2437d2edeaf4d9b56ef279bd0d71127440c067aa
registry.ranchercarbide.dev/rancher/hardened-k8s-metrics-server:v0.8.1-build20260513
registry.ranchercarbide.dev/rancher/kube-webhook-certgen:v1.14.5-hardened2
registry.ranchercarbide.dev/rancher/klipper-helm:v0.10.0-build20260513
registry.ranchercarbide.dev/rancher/hardened-k8s-metrics-server:v0.8.1-build20260513
registry.ranchercarbide.dev/rancher/mirrored-pause:3.6
registry.ranchercarbide.dev/rancher/nginx-ingress-controller:v1.14.5-hardened2
registry.ranchercarbide.dev/rancher/rke2-runtime:v1.35.5-rke2r2
registry.ranchercarbide.dev/rancher/mirrored-cilium-hubble-ui-backend:v0.13.3
registry.ranchercarbide.dev/rancher/hardened-dns-node-cache:1.26.8-build20260511
registry.ranchercarbide.dev/rancher/mirrored-cilium-hubble-ui:v0.13.3
registry.ranchercarbide.dev/rancher/mirrored-cilium-clustermesh-apiserver:v1.19.3
registry.ranchercarbide.dev/rancher/hardened-cni-plugins:v1.9.1-build20260511
registry.ranchercarbide.dev/rancher/mirrored-cilium-operator-aws:v1.19.3
registry.ranchercarbide.dev/rancher/hardened-etcd:v3.6.7-k3s1-build20260512
registry.ranchercarbide.dev/rancher/mirrored-cilium-hubble-relay:v1.19.3
registry.ranchercarbide.dev/rancher/hardened-cni-plugins:v1.9.1-build20260511
registry.ranchercarbide.dev/rancher/hardened-snapshot-controller:v8.5.0-build20260513
registry.ranchercarbide.dev/rancher/rke2-cloud-provider:v1.35.4-0.20260415195656-e51c0636351d-build20260415
registry.ranchercarbide.dev/rancher/kube-webhook-certgen:v1.14.5-hardened2
registry.ranchercarbide.dev/rancher/hardened-traefik:v3.6.16-build20260512
registry.ranchercarbide.dev/rancher/nginx-ingress-controller:v1.14.5-hardened2
registry.ranchercarbide.dev/rancher/hardened-cluster-autoscaler:v1.10.3-build20260511
registry.ranchercarbide.dev/rancher/mirrored-cilium-operator-azure:v1.19.3
registry.ranchercarbide.dev/rancher/hardened-snapshot-controller:v8.5.0-build20260513
registry.ranchercarbide.dev/rancher/mirrored-pause:3.6
registry.ranchercarbide.dev/rancher/mirrored-cilium-hubble-ui-backend:v0.13.3
registry.ranchercarbide.dev/rancher/mirrored-cilium-certgen:v0.4.1
registry.ranchercarbide.dev/rancher/hardened-coredns:v1.14.3-build20260511
registry.ranchercarbide.dev/rancher/hardened-kubernetes:v1.35.5-rke2r2-build20260521
registry.ranchercarbide.dev/rancher/klipper-lb:v0.4.17
registry.ranchercarbide.dev/rancher/mirrored-cilium-certgen:v0.4.1
registry.ranchercarbide.dev/rancher/klipper-helm:v0.10.0-build20260513
registry.ranchercarbide.dev/rancher/hardened-kubernetes:v1.35.5-rke2r2-build20260521
registry.ranchercarbide.dev/rancher/mirrored-cilium-hubble-ui:v0.13.3
```

Show where to find the default admin's kubeconfig but explain how it is limited.

```console
# yq '.users[0].user.client-certificate-data' /etc/rancher/rke2/rke2.yaml | base64 -d | openssl x509 -subject -noout
subject=O=system:masters, CN=system:admin
```

The default admin, identified in Kubernetes by the subject CN `system:admin`, is not allowed to create clusters. The kubeconfig generated by Rancher instead creates a bearer token bound to the specific user in Rancher's own user db:

```console
$ export KUBECONFIG="$(pwd)/local.yaml"
$ yq '.users[0].user.token' $KUBECONFIG | cut -d ':' -f 1
kubeconfig-user-6npcdg44tv
$ kubectl get kubeconfig kubeconfig-c8r82 -ojsonpath='{.status.tokens[0]}'
kubeconfig-user-6npcdg44tv
$ kubectl get tokens.management.cattle.io kubeconfig-user-6npcdg44tv -ojsonpath='{.userPrincipal}' | jq '.'
{
  "displayName": "adam.acosta.rgs@gmail.com",
  "loginName": "adam.acosta.rgs@gmail.com",
  "me": true,
  "metadata": {
    "name": "cognito_user://015b6500-f071-7026-7f40-14da486744ec"
  },
  "principalType": "user",
  "provider": "cognito"
}
```

We see this is not the default admin user created by RKE2, but rather me, a user authenticated through Amazon Cognito. We can see this actually implements some of the recommended CIS controls but the scanner can't tell because it is implemented by proxying the API server through Rancher rather than modifying Kubernetes directly.