# Deployment notes

## EC2 node driver

### Security groups

Rancher automatically creates a security group called "rancher-nodes" if no pre-created group is selected. We simply pass that name to the Terraform provider. You cannot pass a real security group ID. If you want to use a pre-created group, you have to choose it by name, not id. The documentation for the provider is lacking in this area, though the UI makes this more clear because it uses a pre-populated drop-down menu.

The documentation for required IAM policies is not complete, either. The job will attempt to add an egress rule for IPv6, which not matter unless you're actually using a dual-stack or IPv6 network, but it will fail because of insufficient permissions. It needs `ec2:AuthorizeSecurityGroupEgress`, which is added in the IaC here but not shown in the documentation.

See [Rancher AWS EC2 Security Group](https://ranchermanager.docs.rancher.com/v2.14/getting-started/installation-and-upgrade/installation-requirements/port-requirements#rancher-aws-ec2-security-group) for the default rules that Rancher creates for node driver clusters.