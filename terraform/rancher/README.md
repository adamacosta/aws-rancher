# AWS Rancher

This example demonstrates deploying Rancher on an RKE2 cluster in AWS.

## Retrieving `kubeconfig`

`rke2-aws-tf` uses `cloud-init` scripts to upload the default admin user's `kubeconfig` file to an S3 bucket, the path to which is stored in the `terraform` outputs. We can query that and retrieve the file to use it thusly:

```sh
aws s3 cp $(terraform output -json | jq -r '.rke2.value.kubeconfig_path') .
export KUBECONFIG="$(pwd)/rke2.yaml"
```

## Registry auth

Assuming you have a file named `.env` with the variables `CARBIDE_USER` and `CARBIDE_PASSWORD`, use that to generate a secret for Carbide registry auth:

```sh
source .env
kubectl create secret docker-registry carbide-registry \
  --namespace kube-system \
  --docker-email="adam.acosta@ranchergovernment.com" \
  --docker-password="$CARBIDE_PASSWORD" \
  --docker-server="registry.ranchercarbide.dev" \
  --docker-username="$CARBIDE_USER" --output yaml --dry-run=client
```

## IPs

To get the public IPs for the control plane nodes:

```console
$ aws ec2 describe-instances --instance-ids $(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name $(terraform output -json | jq -r '.rke2.value.server_nodepool_name') --no-cli-pager --query 'AutoScalingGroups[0].Instances[*].InstanceId' --output text) --no-cli-pager --query 'Reservations[*].Instances[0].PublicIpAddress' --output text | tr '\t' ' '
3.145.23.68 18.216.236.104 18.220.64.70
```

To generate a `tmuxinator` config to get a sync'd ssh session to all at the same time:

```sh
CP_ASG_NAME=$(terraform output -json | jq -r '.rke2.value.server_nodepool_name')
CP_PUBLIC_IPS=$(aws ec2 describe-instances \
  --instance-ids $(aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-name "$CP_ASG_NAME" \
    --no-cli-pager \
    --query 'AutoScalingGroups[0].Instances[*].InstanceId' \
    --output text) \
  --no-cli-pager \
  --query 'Reservations[*].Instances[0].PublicIpAddress' \
  --output text |
  tr '\t' ' ')
cat <<EOF > "$HOME/.config/tmuxinator/$CP_ASG_NAME.yml"
name: $CP_ASG_NAME
root: ~/

windows:
  - editor:
      layout: even-vertical
      synchronize: after
      panes:
EOF
for ip in "${(s/ /)CP_PUBLIC_IPS}"; do echo "        - ssh rancher@$ip" >> "$HOME/.config/tmuxinator/$CP_ASG_NAME.yml"; done
```

Then to start a session:

```sh
tmuxinator start "$CP_ASG_NAME"
```

## Identify the cluster initializer

A Kubernetes control plane has the notion of an "initializer" node, which is not well-defined or a standardized term, but reflects the fact that one node has to create the cluster, while others join an existing cluster. This is a challenge for automation and usually results in a multi-step process whereby a one-node cluster is created, the auto-generated join token is retrieved, the join token and API server url are passed to all other nodes, then those nodes join.

`rke2-aws-tf` gets around that by (1) using the `terraform` `random` provider to pre-generate a join token and place it onto all nodes via `cloud-init` `user-data`, and (2) by performing a form of leader election whereby each node first checks to see if the LB URL it was passed is already listening on the `rke2` supervisor port 9345. If it is, join that cluster. Otherwise, list all of the instance IDs of its node group, sort them lexicographically, then create a new cluster if the first instance ID in the list matches its own instance ID. Otherwise, poll the load balancer forever until it is listening, then join.

Because `cloud-init` stores its scripts, users can interactively run the same function. To do so:

```sh
grep -A18 'elect_leader()' /var/lib/cloud/instance/scripts/20_rke2.sh | sed 's/ info / echo /' > elect_leader.sh
source elect_leader.sh
elect_leader
```

For example:

```console
ip-10-100-159-187:~ # elect_leader
Current instance: i-0da92675fcb5b972c | Leader instance: i-0079aa551382e5bc3
Electing as joining server
───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
ip-10-100-98-235:~ # elect_leader
Current instance: i-042870a9819668425 | Leader instance: i-0079aa551382e5bc3
Electing as joining server
───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
ip-10-100-68-96:~ # elect_leader
Current instance: i-0079aa551382e5bc3 | Leader instance: i-0079aa551382e5bc3
Electing as cluster leader
```

This is compressed to show every pane but only the required info, showing the third EC2 instance in the list has the lexicographically first instance ID and thus became the leader. You could, of course, also simply look for the `server: ` block in `/etc/rancher/rke2/config.yaml`, but this is more brittle because it will not work if instances are refreshed to pick up a new launch template without creating a new cluster, as then all nodes will show as joiners rather than creators.

Finally, you can simply run a similar process yourself. The code is [here](https://github.com/ranchergovernment/rke2-aws-tf/blob/main/modules/userdata/files/rke2-init.sh#L49C1-L68C2):

```sh
# The most simple "leader election" you've ever seen in your life
elect_leader() {
  # Fetch other running instances in ASG
  TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
  instance_id=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
  asg_name=$(aws autoscaling describe-auto-scaling-instances --instance-ids "$instance_id" --query 'AutoScalingInstances[*].AutoScalingGroupName' --output text)
  instances=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name "$asg_name" --query 'AutoScalingGroups[*].Instances[?HealthStatus==`Healthy`].InstanceId' --output text)

  # Simply identify the leader as the first of the instance ids sorted alphanumerically
  leader=$(echo $instances | tr ' ' '\n' | sort -n | head -n1)

  info "Current instance: $instance_id | Leader instance: $leader"

  if [ "$instance_id" = "$leader" ]; then
    SERVER_TYPE="leader"
    info "Electing as cluster leader"
  else
    info "Electing as joining server"
  fi
}
```

In principle, this could have been simplified and not required the use of `awscli`, since an autoscaling group adds tags to each instance showing its membership in an autoscaling group. For example:

```console
$ aws ec2 describe-instances --instance-ids i-0079aa551382e5bc3 --no-cli-pager --query 'Reservations[0].Instances[0].Tags'
[
    {
        "Key": "kubernetes.io/cluster/rancher-uoc",
        "Value": "owned"
    },
    {
        "Key": "aws:autoscaling:groupName",
        "Value": "rancher-uoc-server-rke2-nodepool"
    },
    {
        "Key": "Name",
        "Value": "rancher-uoc-server-rke2-nodepool"
    },
    {
        "Key": "aws:ec2launchtemplate:version",
        "Value": "1"
    },
    {
        "Key": "Role",
        "Value": "server"
    },
    {
        "Key": "aws:ec2launchtemplate:id",
        "Value": "lt-03fbb3fd56b014c32"
    }
]
```

The problem here is that Kubernetes uses tags with '/' in them to identify membership in a cluster for the cloud provider to know which instances it owns, but this is disallowed when tags are accessible from the EC2 instance metadata service because they are fetched over HTTP and would be interpreted as separators in the path element of the URL. Thus, access to tags from IMDS has to be turned off in order to be able to use the cloud provider. See [kubernetes/cloud-provider-aws/issues/762](https://github.com/kubernetes/cloud-provider-aws/issues/762).

Since, in this case, we are using resource names for node names, we can also just sort the node names to get the cluster initializer that way. The following `awscli` one-liner will do it:

```sh
aws ec2 describe-instances \
  --instance-ids $(kubectl get node -o custom-columns=:.metadata.name --no-headers | sort | head -n 1) \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text \
  --no-cli-pager
```

Please note this only applies on first deployment. Whenever the autoscaling group is refreshed with a new launch template to perform host OS and/or RKE2 updates, there will no longer be a cluster initializer as all nodes will join to the existing load balancer URL.

## AWS Cloud Credential

See [IAM Role & Instance Profile](https://rancherfederal.github.io/carbide-docs/docs/IC-cloud-support-docs/prereqs#iam-role--instance-profile). Rancher Government has a special feature not available to community Rancher allowing for the use of EC2 instance profiles for the Rancher cluster nodes rather than a long-lived access key to use the EC2 node driver. That is why we are attaching the role to the cluster's control plane profile rather than creating a user with an access key.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.50.0 |
| <a name="provider_http"></a> [http](#provider\_http) | 3.6.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_rke2"></a> [rke2](#module\_rke2) | git@github.com:ranchergovernment/rke2-aws-tf.git | main |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_role_policy.dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.ec2_node_driver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.carbide_creds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_security_group_rule.allow_ping](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_ami.server](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy.carbide_creds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy_document.dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ec2_with_passrole](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_route53_zone.domain](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [http_http.myip](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |
| [http_http.mykeys](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |

## Inputs

No inputs.

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_rke2"></a> [rke2](#output\_rke2) | n/a |
<!-- END_TF_DOCS -->