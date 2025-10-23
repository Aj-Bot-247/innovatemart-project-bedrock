output "cluster_name" {
  description = "The name of the EKS cluster."
  value       = aws_eks_cluster.innovatemart_cluster.name
}

output "cluster_endpoint" {
  description = "The endpoint for your EKS Kubernetes API server."
  value       = aws_eks_cluster.innovatemart_cluster.endpoint
}

output "cluster_ca_certificate" {
  description = "The certificate authority data for the EKS cluster."
  value       = aws_eks_cluster.innovatemart_cluster.certificate_authority[0].data
}

output "developer_user_access_key_id" {
  description = "The access key ID for the read-only developer user. Store this securely."
  value       = aws_iam_access_key.developer_user_key.id
  sensitive   = true
}

output "developer_user_secret_access_key" {
  description = "The secret access key for the read-only developer user. Store this securely."
  value       = aws_iam_access_key.developer_user_key.secret
  sensitive   = true
}
output "ebs_csi_driver_role_arn" {
  description = "The ARN of the IAM role for the EBS CSI driver."
  value       = aws_iam_role.ebs_csi_driver_role.arn
}