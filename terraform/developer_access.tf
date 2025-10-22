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
  user_name = aws_iam_user.developer_user.name
  depends_on = [aws_iam_user.developer_user]
}