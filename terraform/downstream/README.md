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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |
| <a name="requirement_rancher2"></a> [rancher2](#requirement\_rancher2) | ~> 14.1 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.50.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_ds_app_dev"></a> [ds\_app\_dev](#module\_ds\_app\_dev) | ./modules/cluster | n/a |
| <a name="module_ds_app_prod"></a> [ds\_app\_prod](#module\_ds\_app\_prod) | ./modules/cluster | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_instance_profile.aws_ccm_ebs_csi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.aws_ccm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.ebs_csi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_policy.ebs_csi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy_document.aws_ccm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.instance_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

No inputs.

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ds_app_dev"></a> [ds\_app\_dev](#output\_ds\_app\_dev) | n/a |
| <a name="output_ds_app_prod"></a> [ds\_app\_prod](#output\_ds\_app\_prod) | n/a |
<!-- END_TF_DOCS -->