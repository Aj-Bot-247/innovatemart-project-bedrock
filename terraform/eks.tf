# This file provisions the EKS cluster and its associated node group.

# --- Kubernetes Provider Configuration ---
provider "kubernetes" {
  host                   = aws_eks_cluster.innovatemart_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.innovatemart_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.innovatemart_cluster.name
}

# This gets the certificate thumbprint needed to create the OIDC provider
data "tls_certificate" "eks_cluster_issuer" {
  url = aws_eks_cluster.innovatemart_cluster.identity[0].oidc[0].issuer
}

# This creates the OIDC provider in IAM
resource "aws_iam_openid_connect_provider" "eks_oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_cluster_issuer.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.innovatemart_cluster.identity[0].oidc[0].issuer
}

resource "aws_eks_cluster" "innovatemart_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = concat(
      [for subnet in aws_subnet.public_subnets : subnet.id],
      [for subnet in aws_subnet.private_subnets : subnet.id]
    )
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
  ]
}

resource "aws_eks_node_group" "innovatemart_node_group" {
  cluster_name    = aws_eks_cluster.innovatemart_cluster.name
  node_group_name = "innovatemart-managed-nodes"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = [for subnet in aws_subnet.private_subnets : subnet.id]

  # Cost-saving measure: using t3.medium instances.
  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ec2_container_registry_read_only,
  ]
}

# --- EKS aws-auth ConfigMap for Developer Access ---

resource "kubernetes_config_map_v1_data" "aws_auth" {
  provider = kubernetes

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  force = true # Allows Terraform to overwrite the ConfigMap

  data = {
    "mapUsers" = yamlencode(
      concat(
        [
          {
            userarn  = data.aws_iam_user.developer_user_data.arn
            username = data.aws_iam_user.developer_user_data.user_name
            groups   = ["viewers"]
          }
        ],
        yamldecode(
          try(
            data.kubernetes_config_map_v1.aws_auth.data["mapUsers"],
            "[]"
          )
        )
      )
    )
    "mapRoles" = yamlencode([
      {
        rolearn  = aws_iam_role.eks_node_group_role.arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups = [
          "system:bootstrappers",
          "system:nodes"
        ]
      }
    ])
  }

  depends_on = [
    aws_eks_cluster.innovatemart_cluster,
    aws_iam_user.developer_user,
  ]
}

data "kubernetes_config_map_v1" "aws_auth" {
  provider = kubernetes

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  depends_on = [aws_eks_cluster.innovatemart_cluster]
}

