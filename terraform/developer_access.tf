# This fetches the Account ID, which is needed to build the policy ARN
data "aws_caller_identity" "current" {}

# --- IAM User & Keys ---

# Creates the IAM user for the development team.
resource "aws_iam_user" "developer_user" {
  name = var.developer_iam_user_name
  path = "/users/"
}

# Creates access keys for the user. The output file will contain these.
resource "aws_iam_access_key" "developer_user_key" {
  user = aws_iam_user.developer_user.name
}

# This data source allows Terraform to dynamically construct the ARN
# for the user we just created, which we need for the Kubernetes RBAC.
data "aws_iam_user" "developer_user_data" {
  user_name  = aws_iam_user.developer_user.name
  depends_on = [aws_iam_user.developer_user]
}

# --- IAM POLICY FOR DEVELOPER READ-ONLY EKS ACCESS ---

# 1. Define the EKS Read-Only Policy Document
# This allows the user to run 'aws eks update-kubeconfig' and view basic cluster info.
data "aws_iam_policy_document" "developer_eks_readonly" {
  statement {
    sid    = "AllowEKSDescribe"
    effect = "Allow"
    actions = [
      "eks:DescribeCluster",
      "eks:ListClusters",
      "eks:ListNodegroups",
    ]
    # Restrict to the specific cluster ARN for best practice
    resources = [
      "arn:aws:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${var.cluster_name}",
      "arn:aws:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:nodegroup/*/*"
    ]
  }
}

# 2. Create the managed policy in AWS
resource "aws_iam_policy" "developer_eks_readonly_policy" {
  name        = "InnovateMart-DeveloperEKSReadOnly"
  description = "Allows EKS DescribeCluster for kubeconfig generation."
  policy      = data.aws_iam_policy_document.developer_eks_readonly.json
}

# 3. Attach the policy to the developer user
resource "aws_iam_user_policy_attachment" "developer_eks_readonly_attach" {
  user       = aws_iam_user.developer_user.name
  policy_arn = aws_iam_policy.developer_eks_readonly_policy.arn
}