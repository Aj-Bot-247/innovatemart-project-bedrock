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
# --- Outputs for Bonus Objective: Managed Persistence ---

output "rds_postgresql_endpoint" {
  description = "The endpoint of the RDS PostgreSQL instance for the orders service."
  value       = aws_db_instance.orders_db.endpoint
}

output "rds_mysql_endpoint" {
  description = "The endpoint of the RDS MySQL instance for the catalog service."
  value       = aws_db_instance.catalog_db.endpoint
}

output "dynamodb_table_name" {
  description = "The name of the DynamoDB table for the carts service."
  value       = aws_dynamodb_table.carts_db.name
}

output "rds_database_password" {
  description = "The generated password for the RDS databases. Store securely."
  value       = random_password.rds_password.result
  sensitive   = true # This hides the password in logs for security
}

output "alb_controller_role_arn" {
  description = "The ARN of the IAM role for the AWS Load Balancer Controller."
  value       = aws_iam_role.alb_controller_role.arn
}

output "vpc_id" {
  description = "The ID of the VPC."
  value       = aws_vpc.innovatemart_vpc.id
}