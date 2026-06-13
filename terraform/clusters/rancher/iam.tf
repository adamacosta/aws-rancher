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