# awscli

## JMESPath

[JMESpath](https://jmespath.org/) is the query language used by `awscli`. It has roughly the same capabilities as `jq` but is quite different in syntax. Output from `awscli <command> <args> --no-cli-pager --output json` can be piped to `jq`, but if you wish to use the native query capability in the CLI itself, the home page for the query language has tutorials and a built-in playground where you can test queries to see what they return.

## Analogs to Terraform data resource queries

Terraform:

```hcl
data "aws_ami" "sles" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["suse-sles-16-0-v*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}
```

AWS CLI:

```console
$ aws ec2 describe-images \
  --owners "amazon" \
  --filters "Name=architecture,Values=x86_64" "Name=name,Values=suse-sles-16-0-v*" \
  --no-cli-pager \
  --output text \
  --query "sort_by(Images, &CreationDate)[-1].ImageId"
ami-0492bfa56020b2a15
```

Terraform:

```hcl
data "aws_vpc" "demo" {
  filter {
    name   = "tag:Name"
    values = ["aacosta-demo"]
  }
}
```

AWS CLI:

```console
$ aws ec2 describe-vpcs \
  --filter "Name=tag:Name,Values=aacosta-demo" \
  --no-cli-pager \
  --output text \
  --query "Vpcs[0].VpcId"
vpc-0802dac85e3a9d532
```

Terraform:

```hcl
data "aws_subnet" "public" {
  vpc_id = data.aws_vpc.demo.id

  filter {
    name   = "availability-zone"
    values = ["${local.region}${local.availability_zone}"]
  }

  filter {
    name   = "tag:Name"
    values = ["*-public-*"]
  }
}
```

AWS CLI:

```console
$ aws ec2 describe-subnets \
  --filter "Name=vpc-id,Values=vpc-0802dac85e3a9d532" \
  --filter "name=availability-zone,Values=us-east-2a" \
  --filter "Name=tag:Name,Values=*-public-*" \
  --no-cli-pager \
  --output text \
  --query "Subnets[0].SubnetId"
subnet-0d216efdf36457bb0
```