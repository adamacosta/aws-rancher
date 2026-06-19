# aws-sles-rke2

Packer build to create an AMI with SLES as the OS layer and RKE2 pre-installed and pre-seeded with the container images required to run all of its static pods and addons. A separate EBS volume is added and split into two partitions for `/var/lib/kubelet` and `/var/lib/rancher`.

## Usage

```sh
packer build -var-file=us-east-2.pkrvars.hcl .
```

To perform a debug build that allows you to manually step through each build phase:

```sh
packer build -var-file=us-east-2.pkrvars.hcl -debug .
```

Packer, by default, creates a temporary key pair that is only stored in-memory that is used as the key pair associated with the EC2 instanced launched in order to create an ami from. When run in debug mode, it will write the private key to disk in the directory Packer is being run from, and you can use that to ssh to the host while the build is paused in order to check out the machine and troubleshoot:

```sh
ssh -i sles_base.pem ec2-user@<ec2-public-ip>
```

Note that a public subnet is chosen intentionally to build in so that it is possible to assign a public IP. Otherwise, the SSM communicator would need to be used instead of ssh.