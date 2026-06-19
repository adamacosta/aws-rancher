# AWS Network

We are creating a VPC with three public and three private subnets, tied to availability zones `a`, `b`, and `c` of the respective region chosen, which defaults to `us-east-2` for no good reason other than it is geographically closest to me. A VPN client endpoint is also created but appears not to work currently the AWS account we use for internal operations does not seem to allow the default SAML provider to be used. We can only use Okta to authenticate to IAM identity center but have no ability as SAs/FEs to configure Okta for this to work. A workable VPN probably needs to use client certificate authentication instead, which will be attempted in the future. This same setup worked for a customer that used Azure Entra ID as the IDP behind IAM identity center, but we were able to instruct their corporate IT on how to setup a SAML application in Entra ID for IAM identity center to use.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.50.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_acm_certificate.vpn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_ec2_client_vpn_authorization_rule.vpn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_client_vpn_authorization_rule) | resource |
| [aws_ec2_client_vpn_endpoint.vpn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_client_vpn_endpoint) | resource |
| [aws_ec2_client_vpn_network_association.vpn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_client_vpn_network_association) | resource |
| [aws_iam_saml_provider.vpn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_saml_provider) | resource |
| [aws_route53_record.vpn_certificate_validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_security_group.vpn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_iam_saml_provider.sso](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_saml_provider) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_route53_zone.domain](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_cidr"></a> [cidr](#input\_cidr) | IPv4 CIDR range for the VPC. The default is chosen to avoid overlap with what seem to be common example ranges. | `string` | `"10.100.0.0/16"` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | Domain that the VPN server certificate will be a subdomain of. Must be registered via AWS to use ACM. | `string` | `"rgsdemo.com"` | no |
| <a name="input_name"></a> [name](#input\_name) | tag:Name assigned to VPC, which is used by cluster provisioners to automatically find a network to attach to. | `string` | `"aacosta-demo"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region to put the VPC in. | `string` | `null` | no |
| <a name="input_vpn_client_cidr"></a> [vpn\_client\_cidr](#input\_vpn\_client\_cidr) | CIDR range to assign VPC client IPs from. Must not overlap with any subnet the VPC associates with. | `string` | `"172.22.0.0/16"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_vpc"></a> [vpc](#output\_vpc) | n/a |
<!-- END_TF_DOCS -->