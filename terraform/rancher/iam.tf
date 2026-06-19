#
# IAM for Rancher local cluster nodes
#

# Needed for cert-manager and external-dns
data "aws_iam_policy_document" "dns" {
  statement {
    sid = ""
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResources"
    ]
    effect    = "Allow"
    resources = ["arn:aws:route53:::hostedzone/*"]
  }

  statement {
    sid       = ""
    actions   = ["route53:ListHostedZones"]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    sid       = ""
    actions   = ["route53:GetChange"]
    effect    = "Allow"
    resources = ["arn:aws:route53:::change/*"]
  }
}

resource "aws_iam_role_policy" "dns" {
  name   = "${module.rke2.cluster_name}-dns"
  role   = module.rke2.iam_role
  policy = data.aws_iam_policy_document.dns.json
}

data "aws_iam_policy" "carbide_creds" {
  name = "read-carbide-token-secret"
}

resource "aws_iam_role_policy_attachment" "carbide_creds" {
  role       = module.rke2.iam_role
  policy_arn = data.aws_iam_policy.carbide_creds.arn
}

#
# IAM for cloud credential
#

# https://ranchermanager.docs.rancher.com/how-to-guides/new-user-guides/launch-kubernetes-with-rancher/use-new-nodes-in-an-infra-provider/create-an-amazon-ec2-cluster#example-iam-policy-with-passrole
data "aws_iam_policy_document" "ec2_with_passrole" {
  statement {
    sid = ""
    actions = [
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:Describe*",
      "ec2:ImportKeyPair",
      "ec2:CreateKeyPair",
      "ec2:CreateSecurityGroup",
      "ec2:CreateTags",
      "ec2:DeleteKeyPair",
      "ec2:ModifyInstanceMetadataOptions"
    ]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    sid = ""
    actions = [
      "iam:PassRole",
      "ec2:RunInstances"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:ec2:${local.aws_region}::image/ami-*",
      "arn:aws:ec2:${local.aws_region}:${local.account_id}:instance/*",
      "arn:aws:ec2:${local.aws_region}:${local.account_id}:placement-group/*",
      "arn:aws:ec2:${local.aws_region}:${local.account_id}:volume/*",
      "arn:aws:ec2:${local.aws_region}:${local.account_id}:subnet/*",
      "arn:aws:ec2:${local.aws_region}:${local.account_id}:key-pair/*",
      "arn:aws:ec2:${local.aws_region}:${local.account_id}:network-interface/*",
      "arn:aws:ec2:${local.aws_region}:${local.account_id}:security-group/*",
      "arn:aws:iam::${local.account_id}:role/*"
    ]
  }

  statement {
    sid = ""
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:Encrypt",
      "kms:DescribeKey",
      "kms:CreateGrant",
      "ec2:DetachVolume",
      "ec2:AttachVolume",
      "ec2:DeleteSnapshot",
      "ec2:DeleteTags",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:DeleteVolume",
      "ec2:CreateSnapshot"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:ec2:${local.aws_region}:${local.account_id}:volume/*",
      "arn:aws:ec2:${local.aws_region}:${local.account_id}:instance/*",
      "arn:aws:ec2:${local.aws_region}:${local.account_id}:snapshot/*",
      "arn:aws:kms:${local.aws_region}:${local.account_id}:key/*"
    ]
  }

  statement {
    sid = ""
    actions = [
      "ec2:RebootInstances",
      "ec2:TerminateInstances",
      "ec2:StartInstances",
      "ec2:StopInstances"
    ]
    effect    = "Allow"
    resources = ["arn:aws:ec2:${local.aws_region}:${local.account_id}:instance/*"]
  }
}

resource "aws_iam_role_policy" "ec2_node_driver" {
  name   = "${module.rke2.cluster_name}-ec2-node-driver"
  role   = module.rke2.iam_role
  policy = data.aws_iam_policy_document.ec2_with_passrole.json
}