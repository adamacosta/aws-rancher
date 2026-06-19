# Troubleshooting

## Cluster provisioning logs

If anything goes wrong during deployment, the Rancher logs and UI status will not show much detail. You need to look for the job created to create the machines in the `fleet-default` namespace. They will match the machine pool name. The pod logs for the job will show the error in enough detail to remediate.

Examples:

```console
$ kubectl get jobs -n fleet-default
NAME                                                       STATUS     COMPLETIONS   DURATION   AGE
ds-ec2-node-driver-cp-l8vlz-srgkc-machine-provision        Complete   1/1           9s         2m42s
ds-ec2-node-driver-workers-qtp5m-h9sbk-machine-provision   Complete   1/1           9s         2m42s
$ kubectl logs -n fleet-default jobs/ds-ec2-node-driver-cp-l8vlz-srgkc-machine-provision
Trying to access option  which does not exist
THIS ***WILL*** CAUSE UNEXPECTED BEHAVIOR
Type assertion did not go smoothly to string for key
Running pre-create checks...
Creating machine...
(ds-ec2-node-driver-cp-l8vlz-srgkc) Launching instance...
(ds-ec2-node-driver-cp-l8vlz-srgkc) Creating New SSH Key
(ds-ec2-node-driver-cp-l8vlz-srgkc) Creating key pair: ds-ec2-node-driver-cp-l8vlz-srgkc-qbgOT
(ds-ec2-node-driver-cp-l8vlz-srgkc) Configuring security groups in vpc-0802dac85e3a9d532
(ds-ec2-node-driver-cp-l8vlz-srgkc) Found existing security group (rancher-nodes) in vpc-0802dac85e3a9d532
(ds-ec2-node-driver-cp-l8vlz-srgkc) Launching instance in subnet subnet-0d216efdf36457bb0
(ds-ec2-node-driver-cp-l8vlz-srgkc) Building tags for instance creation
(ds-ec2-node-driver-cp-l8vlz-srgkc) Waiting for ip address to become available
(ds-ec2-node-driver-cp-l8vlz-srgkc) Error fetching IPv4 address: no public IPv4 address for instance i-09559f6d4f106e0f0
(ds-ec2-node-driver-cp-l8vlz-srgkc) Get the IPv4 address: "18.118.227.171"
(ds-ec2-node-driver-cp-l8vlz-srgkc) Waiting for instance to be in the running state
(ds-ec2-node-driver-cp-l8vlz-srgkc) Created instance ID i-09559f6d4f106e0f0, Public IPv4 address 18.118.227.171, Private IPv4 address 10.100.68.83, IPv6 address
Waiting for machine to be running, this may take a few minutes...
Custom install script was sent via userdata, provisioning complete...
$ kubectl logs -n fleet-default jobs/ds-ec2-node-driver-workers-qtp5m-h9sbk-machine-provision
Trying to access option  which does not exist
THIS ***WILL*** CAUSE UNEXPECTED BEHAVIOR
Type assertion did not go smoothly to string for key
Running pre-create checks...
Creating machine...
(ds-ec2-node-driver-workers-qtp5m-h9sbk) Launching instance...
(ds-ec2-node-driver-workers-qtp5m-h9sbk) Creating New SSH Key
(ds-ec2-node-driver-workers-qtp5m-h9sbk) Creating key pair: ds-ec2-node-driver-workers-qtp5m-h9sbk-Rfusd
(ds-ec2-node-driver-workers-qtp5m-h9sbk) Configuring security groups in vpc-0802dac85e3a9d532
(ds-ec2-node-driver-workers-qtp5m-h9sbk) Found existing security group (rancher-nodes) in vpc-0802dac85e3a9d532
(ds-ec2-node-driver-workers-qtp5m-h9sbk) Launching instance in subnet subnet-0d216efdf36457bb0
(ds-ec2-node-driver-workers-qtp5m-h9sbk) Building tags for instance creation
(ds-ec2-node-driver-workers-qtp5m-h9sbk) Waiting for ip address to become available
(ds-ec2-node-driver-workers-qtp5m-h9sbk) Error fetching IPv4 address: no public IPv4 address for instance i-0ed769ead178c0bb1
(ds-ec2-node-driver-workers-qtp5m-h9sbk) Get the IPv4 address: "18.191.140.68"
(ds-ec2-node-driver-workers-qtp5m-h9sbk) Waiting for instance to be in the running state
(ds-ec2-node-driver-workers-qtp5m-h9sbk) Created instance ID i-0ed769ead178c0bb1, Public IPv4 address 18.191.140.68, Private IPv4 address 10.100.72.1, IPv6 address
Waiting for machine to be running, this may take a few minutes...
Custom install script was sent via userdata, provisioning complete...
(ds-ec2-node-driver-workers-qtp5m-h9sbk) Closing plugin on server side
(temp-driver-loader) Closing plugin on server side
```