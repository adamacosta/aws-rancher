# Downstream cluster with EC2 node driver

## Auth to Rancher local cluster

You must create an API token using a kubeconfig generated for your user. The default user `system:admin`, which is the kubeconfig found on the cluster nodes at `/etc/rancher/rke2/rke2.yaml` for RKE2 clusters, cannot create tokens. To create a kubeconfig for your user, login to the Rancher UI, go the page for the local cluster, and select the "download kubeconfig" button. This will download a file called `local.yaml`. Download it to this directory and then run:

```sh
export KUBECONFIG="$(pwd)/local.yaml"
```

## API token for Terraform provider to use

Token ttl defaults to 90 days:

```console
$ kubectl get setting auth-token-max-ttl-minutes -ojsonpath='{.default}' | { read ttl; echo "$((ttl / 60 / 24))"}
90
```

DO NOT GENERATE AN IMPERATIVE TOKEN! This is important. See [terraform-provider-rancher2/issues/2106](https://github.com/rancher/terraform-provider-rancher2/issues/2106). `tokens.ext.cattle.io` will allow you create resources but not update them. Instead, pull the token out of the `local.yaml` file downloaded from the UI, which still uses the `tokens.management.cattle.io` API resource.

```sh
cat <<EOF > .env
export RANCHER_TOKEN_KEY=$(yq '.users[] | select(.name=="rancher").user.token' local.yaml)
EOF
source .env
```

This environment variable can now be used by the `rancher2` Terraform provider to create AND update resources.

## Auth to downstreams

The cluster owner's JWT `kubeconfig` is added as a Terraform output to each downstream. To save them:

```sh
for cluster in $(terraform output -json | jq 'keys[]'); do
  terraform output -json | jq -r --arg cluster "$cluster" '.[$cluster] | .value.kube_config' > "${cluster}.yaml"
  chmod 0600 "${cluster}.yaml"
done
```

Note this only works in `zsh` if `setopt SH_WORD_SPLIT` has been set. Otherwise, `zsh` does not split strings with whitespace into arrays.