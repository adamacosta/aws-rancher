# Tips and tricks

## RKE2

Since all of the Kubernetes control plane components, `etcd`, and `kube-proxy` (if used) are deployed as static pods, you can get the arguments passed to them from the API server:

```console
$ kubectl get pod -n kube-system kube-apiserver-i-0014d99790d7c7604 -ojsonpath='{.spec.containers}' | jq -r '.[] | select(.name=="kube-apiserver").args[]'
--admission-control-config-file=/etc/rancher/rke2/rancher-pss.yaml
--audit-policy-file=/etc/rancher/rke2/audit-policy.yaml
--audit-log-maxage=30
--audit-log-maxbackup=10
--audit-log-maxsize=100
--service-account-extend-token-expiration=false
--allow-privileged=true
--anonymous-auth=false
--api-audiences=https://kubernetes.default.svc.cluster.local,rke2
--audit-log-maxage=30
--audit-log-mode=blocking-strict
--audit-log-path=/var/lib/rancher/rke2/server/logs/audit.log
--authorization-mode=RBAC,Node
--bind-address=0.0.0.0
--cert-dir=/var/lib/rancher/rke2/server/tls/temporary-certs
--client-ca-file=/var/lib/rancher/rke2/server/tls/client-ca.crt
--egress-selector-config-file=/var/lib/rancher/rke2/server/etc/egress-selector-config.yaml
--enable-admission-plugins=NodeRestriction
--enable-aggregator-routing=true
--enable-bootstrap-token-auth=true
--encryption-provider-config=/var/lib/rancher/rke2/server/cred/encryption-config.json
--encryption-provider-config-automatic-reload=true
--etcd-cafile=/var/lib/rancher/rke2/server/tls/etcd/server-ca.crt
--etcd-certfile=/var/lib/rancher/rke2/server/tls/etcd/client.crt
--etcd-keyfile=/var/lib/rancher/rke2/server/tls/etcd/client.key
--etcd-servers=https://127.0.0.1:2379
--kubelet-certificate-authority=/var/lib/rancher/rke2/server/tls/server-ca.crt
--kubelet-client-certificate=/var/lib/rancher/rke2/server/tls/client-kube-apiserver.crt
--kubelet-client-key=/var/lib/rancher/rke2/server/tls/client-kube-apiserver.key
--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
--profiling=false
--proxy-client-cert-file=/var/lib/rancher/rke2/server/tls/client-auth-proxy.crt
--proxy-client-key-file=/var/lib/rancher/rke2/server/tls/client-auth-proxy.key
--requestheader-allowed-names=system:auth-proxy
--requestheader-client-ca-file=/var/lib/rancher/rke2/server/tls/request-header-ca.crt
--requestheader-extra-headers-prefix=X-Remote-Extra-
--requestheader-group-headers=X-Remote-Group
--requestheader-username-headers=X-Remote-User
--secure-port=6443
--service-account-issuer=https://kubernetes.default.svc.cluster.local
--service-account-key-file=/var/lib/rancher/rke2/server/tls/service.key
--service-account-signing-key-file=/var/lib/rancher/rke2/server/tls/service.current.key
--service-cluster-ip-range=10.43.0.0/16
--service-node-port-range=30000-32767
--storage-backend=etcd3
--tls-cert-file=/var/lib/rancher/rke2/server/tls/serving-kube-apiserver.crt
--tls-cipher-suites=TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305
--tls-min-version=VersionTLS13
--tls-private-key-file=/var/lib/rancher/rke2/server/tls/serving-kube-apiserver.key
```

This, for instance, aggregates the custom arguments we specified in `/etc/rancher/rke2/config.yaml` in the `kube-apiserver-arg` array with all the defaults built into RKE2.

## Rancher

### Logs

To stream Rancher application logs:

```sh
kubectl logs -n cattle-system -l app=rancher -c rancher -f
```

To stream audit logs:

```sh
kubectl logs -n cattle-system -l app=rancher -c rancher -f
```

### API resources

To see all available categories:

```console
$ kubectl api-resources -oyaml | yq '.resources[] | .categories' | grep -v null | sed 's/- //' | sort -u
all
api-extensions
catalog
cert-manager
cert-manager-acme
cilium
ciliumpolicy
cluster-api
fleet
gateway-api
provisioning
upgrade
```

To see all the groups:

```console
$ kubectl api-resources -oyaml | yq '.resources[] | .group' | grep -v null | sed 's/- //' | sort -u
acme.cert-manager.io
addons.cluster.x-k8s.io
admissionregistration.k8s.io
apiextensions.k8s.io
apiregistration.k8s.io
apps
auditlog.cattle.io
authentication.k8s.io
authorization.k8s.io
autoscaling
batch
catalog.cattle.io
cert-manager.io
certificates.k8s.io
cilium.io
cluster.x-k8s.io
coordination.k8s.io
discovery.k8s.io
events.k8s.io
ext.cattle.io
externaldns.k8s.io
fleet.cattle.io
flowcontrol.apiserver.k8s.io
gateway.networking.k8s.io
groupsnapshot.storage.k8s.io
helm.cattle.io
hub.traefik.io
ipam.cluster.x-k8s.io
k3s.cattle.io
management.cattle.io
metrics.k8s.io
networking.k8s.io
node.k8s.io
policy
provisioning.cattle.io
rbac.authorization.k8s.io
resource.k8s.io
rke-machine-config.cattle.io
rke-machine.cattle.io
rke.cattle.io
runtime.cluster.x-k8s.io
scheduling.k8s.io
snapshot.storage.k8s.io
storage.k8s.io
telemetry.cattle.io
traefik.io
turtles-capi.cattle.io
ui.cattle.io
upgrade.cattle.io
```

For the most part, Rancher uses the resources under the `cattle.io` namespace to manage the local and downstream clusters, but it also uses the CAPI resources. First, focus on the `cattle.io` resources:

```console
$ kubectl api-resources -oyaml | yq '.resources[] | .group' | grep -v null | sed 's/- //' | sort -u | grep cattle
auditlog.cattle.io
catalog.cattle.io
ext.cattle.io
fleet.cattle.io
helm.cattle.io
k3s.cattle.io
management.cattle.io
provisioning.cattle.io
rke-machine-config.cattle.io
rke-machine.cattle.io
rke.cattle.io
telemetry.cattle.io
turtles-capi.cattle.io
ui.cattle.io
upgrade.cattle.io
```

To get a full list of all CRDs in `cattle.io` namespace from the API server:

```console
$ kubectl get crd -o custom-columns=:.metadata.name --no-headers | grep 'cattle\.io'
addons.k3s.cattle.io
amazonec2configs.rke-machine-config.cattle.io
amazonec2machines.rke-machine.cattle.io
amazonec2machinetemplates.rke-machine.cattle.io
apiservices.management.cattle.io
apps.catalog.cattle.io
auditpolicies.auditlog.cattle.io
authconfigs.management.cattle.io
azureconfigs.rke-machine-config.cattle.io
azuremachines.rke-machine.cattle.io
azuremachinetemplates.rke-machine.cattle.io
bundledeployments.fleet.cattle.io
bundlenamespacemappings.fleet.cattle.io
bundles.fleet.cattle.io
capiproviders.turtles-capi.cattle.io
clusterctlconfigs.turtles-capi.cattle.io
clustergroups.fleet.cattle.io
clusterproxyconfigs.management.cattle.io
clusterregistrations.fleet.cattle.io
clusterregistrationtokens.fleet.cattle.io
clusterregistrationtokens.management.cattle.io
clusterrepos.catalog.cattle.io
clusterroletemplatebindings.management.cattle.io
clusters.fleet.cattle.io
clusters.management.cattle.io
clusters.provisioning.cattle.io
composeconfigs.management.cattle.io
contents.fleet.cattle.io
custommachines.rke.cattle.io
digitaloceanconfigs.rke-machine-config.cattle.io
digitaloceanmachines.rke-machine.cattle.io
digitaloceanmachinetemplates.rke-machine.cattle.io
dynamicschemas.management.cattle.io
etcdsnapshotfiles.k3s.cattle.io
etcdsnapshots.rke.cattle.io
features.management.cattle.io
fleetworkspaces.management.cattle.io
gitreporestrictions.fleet.cattle.io
gitrepos.fleet.cattle.io
globalrolebindings.management.cattle.io
globalroles.management.cattle.io
groupmembers.management.cattle.io
groups.management.cattle.io
harvesterconfigs.rke-machine-config.cattle.io
harvestermachines.rke-machine.cattle.io
harvestermachinetemplates.rke-machine.cattle.io
helmchartconfigs.helm.cattle.io
helmcharts.helm.cattle.io
helmops.fleet.cattle.io
imagescans.fleet.cattle.io
kontainerdrivers.management.cattle.io
linodeconfigs.rke-machine-config.cattle.io
linodemachines.rke-machine.cattle.io
linodemachinetemplates.rke-machine.cattle.io
managedcharts.management.cattle.io
navlinks.ui.cattle.io
nodedrivers.management.cattle.io
nodepools.management.cattle.io
nodes.management.cattle.io
oidcclients.management.cattle.io
operations.catalog.cattle.io
plans.upgrade.cattle.io
podsecurityadmissionconfigurationtemplates.management.cattle.io
policies.fleet.cattle.io
preferences.management.cattle.io
projectnetworkpolicies.management.cattle.io
projectroletemplatebindings.management.cattle.io
projects.management.cattle.io
proxyendpoints.management.cattle.io
rancherusernotifications.management.cattle.io
rkebootstraps.rke.cattle.io
rkebootstraptemplates.rke.cattle.io
rkeclusters.rke.cattle.io
rkecontrolplanes.rke.cattle.io
roletemplates.management.cattle.io
samltokens.management.cattle.io
schedules.fleet.cattle.io
secretrequests.telemetry.cattle.io
settings.management.cattle.io
tokens.management.cattle.io
uiplugins.catalog.cattle.io
userattributes.management.cattle.io
users.management.cattle.io
vmwarevsphereconfigs.rke-machine-config.cattle.io
vmwarevspheremachines.rke-machine.cattle.io
vmwarevspheremachinetemplates.rke-machine.cattle.io
```

To understand why these are different lists, note that all of the resources under the `ext.cattle.io` namespace are APIs that are delegated via the `kube-apiserver`'s [aggregation layer](https://kubernetes.io/docs/tasks/extend-kubernetes/configure-aggregation-layer/) rather than installed into the API server directly as CRDs. This means Rancher registers these with the API server, taking control of those paths underneath the `/apis/` path matching the resource groups, versions, and kinds that are registered. When these APIs are called, the API server proxies the call to Rancher rather than handling them directly. Read [Setup an Extension API Server](https://kubernetes.io/docs/tasks/extend-kubernetes/setup-extension-api-server/) to understand how Rancher does this.

This can have implications on API availability if you deploy the control plane in an HA manner with at least 3 nodes, but run Rancher with only 1 replica. This is why you will sometimes see errors when using `kubectl` saying it cannot find APIs that are handled by the metrics server. This is because the Kubernetes metrics server is an API extension that is typically deployed with a single replica, so when its only pod is unavailable, all of the API resources it is responsible for become unavailable and the Kubernetes API server returns errors when attempting to forward requests to the registered proxy and getting no response. Since the metrics server's data output is what gets used by the HPA and VPA to autoscale other resources, when it becomes unavailable, autoscaling will also stop working.