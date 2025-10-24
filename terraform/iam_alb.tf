# terraform/iam_alb.tf

data "aws_iam_policy_document" "alb_controller_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks_oidc.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
  }
}

resource "aws_iam_role" "alb_controller_role" {
  name               = "${var.cluster_name}-alb-controller-role"
  assume_role_policy = data.aws_iam_policy_document.alb_controller_assume_role_policy.json
}

resource "aws_iam_policy" "alb_controller_policy" {
  name        = "${var.cluster_name}-alb-controller-policy"
  description = "Policy for the AWS Load Balancer Controller"
  policy      = file("alb_controller_policy.json") # We will create this JSON file next
}

resource "aws_iam_role_policy_attachment" "alb_controller_attach" {
  role       = aws_iam_role.alb_controller_role.name
  policy_arn = aws_iam_policy.alb_controller_policy.arn
}