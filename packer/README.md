# rhel-stig-packer

Packer build to create an ami with a RHEL 8 STIG applied and volumes mounted as launch block devices for:

- `/home`
- `/var/lib/rancher`
- `/var/lib/kubelet`
- `/var/log`
- `/var/log/audit`
- `/var/tmp`
- `/tmp`

## Usage

No STIG applied:

```sh
packer build -var-file=nostig.pkrvars.hcl .
```

STIG applied but FIPS not enabled:

```sh
packer build -var-file=stig.pkrvars.hcl .
```

STIG applied and FIPS enabled:

```sh
packer build -var-file=root-fips.pkrvars.hcl .
```

To perform a debug build that allows you to manually step through each build phase:

```sh
packer build -debug aws-rhel-stig.pkr.hcl
```

Packer, by default, creates a temporary key pair that is only stored in-memory that is used as the key pair associated with the EC2 instanced launched in order to create an ami from. When run in debug mode, it will write the private key to disk in the directory Packer is being run from, and you can use that to ssh to the host while the build is paused in order to check out the machine and troubleshoot:

```sh
ssh -i ec2-rhel8.pem ec2-user@<ec2-public-ip>
```

Note that a public subnet is chosen intentionally to build in so that it is possible to assign a public IP. Otherwise, the SSM communicator would need to be used instead of ssh.

If there is ever any desire to reuse this template but in a different VPC or subnet, these values would need to be changed into variables that could be passed in. For now, this is not intended to be generic.
