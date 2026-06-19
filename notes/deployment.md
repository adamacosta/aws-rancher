# Deployment notes

## EC2 node driver

### Authentication

The `ec2-user` that is created by `cloud-init` has a password of `rancher`. This must be changed on first login.

### Instance type

`m8a.xlarge` is chosen as the default because the M8a family is the general-purpose AMD family that supports Nitro V6. Nitro-enabled instances are needed to be able to use the serial console.

### Security groups

Rancher automatically creates a security group called `rancher-nodes` if no pre-created group is selected. We simply pass that name to the Terraform provider. You cannot pass a real security group ID. If you want to use a pre-created group, you have to choose it by name, not id. The documentation for the provider is lacking in this area, though the UI makes this more clear because it uses a pre-populated drop-down menu.

The documentation for required IAM policies is not complete, either. The job will attempt to add an egress rule for IPv6, which does not matter unless you're actually using a dual-stack or IPv6 network, but it will fail because of insufficient permissions. It needs `ec2:AuthorizeSecurityGroupEgress`, which is added in the IaC here but not shown in the documentation.

See [Rancher AWS EC2 Security Group](https://ranchermanager.docs.rancher.com/v2.14/getting-started/installation-and-upgrade/installation-requirements/port-requirements#rancher-aws-ec2-security-group) for the default rules that Rancher creates for node driver clusters.

### IMDS

IMDS tokens are set to "optional" or IMDSv1. This is because using the out-of-tree cloud provider, or any other cluster-internal service that needs to use the AWS API, requires metadata max hops to be at least one more than what hitting the service from the host requires. IMDSv2 introduces an extra hop for token validation, so needs to be set to 3 for IMDS to be accessible from a container not using the host network. Rancher's EC2 node driver, however, provides no way to set metadata max hops, automatically setting it to 2, which only works if tokens are optional.

## Cert Manager

`cert-manager` only uses what it calls "ambient credentials," including retrieving AWS session tokens over IMDS, to `ClusterIssuer` resources, without setting additional parameters. This is recommended to avoid unprivileged users who are able to create namespaced resources but not cluster-scope resources from being able to access IMDS and gain the credentials of the EC2 instance profile.

## Rancher TLS settings

We choose to externally provision the server certificate for Rancher, even though we are using Let's Encrypt, because Rancher's automatic Let's Encrypt integration uses http01 domain validation and we want to use dns01, allowing `cert-manager` to use the same IAM policy as `external-dns`, writing records to the Route53 public hosted zone for `rgsdemo.com`, which is a domain registered through AWS.

Doing this requires we use the `privateCA: true` Helm value and provide the Let's Encrypt root CA certificate in the `tls-ca` secret. This is created automatically via `cloud-init` user-data after RKE2 starts up and `cert-manager` is installed. The CA certificates can be found at [Chains of Trust](https://letsencrypt.org/certificates/) on the Let's Encrypt home page. The certificate we get is issued by the YR1 intermediate, which is signed by the offline ISRG Root X1. The user-data script downloads the pem-encoded CA certificate from the known URL retrieved from this page.

## Cognito Auth Provider for Rancher

See [Rancher / v2.14 / New User Guides / Configuring Amazon Cognito](https://ranchermanager.docs.rancher.com/v2.14/how-to-guides/new-user-guides/authentication-permissions-and-global-configuration/authentication-config/configure-amazon-cognito).

MFA was turned on and passkeys enabled as a sign-in option. In Rancher, access is limited to selected users, who are identified by e-mail. Two groups are created in Cognito, `admins` and `users`. Roles in Rancher are tied to these groups to demonstrate different permissions for an administrative account and developer account. Additional personas may be added in the future. For now, Cognito and the integration with Rancher was setup manually, but may be done via IaC in the future.