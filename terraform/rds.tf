# This resource is needed to generate a secure, random password for the RDS instances.
resource "random_password" "rds_password" {
  length  = 16
  special = false
  upper   = true
  numeric = true
}

# --- 1. RDS Subnet Group (Required) ---
resource "aws_db_subnet_group" "innovatemart_db_subnet_group" {
  name       = "${var.cluster_name}-db-subnet-group"
  subnet_ids = [for subnet in aws_subnet.private_subnets : subnet.id] 
  tags = {
    Name = "${var.cluster_name}-db-subnet-group"
  }
}

# --- 2. RDS Security Group (Allows traffic from EKS Nodes) ---
resource "aws_security_group" "rds_sg" {
  name        = "${var.cluster_name}-rds-sg"
  description = "Allow EKS Node Group to connect to RDS"
  vpc_id      = aws_vpc.innovatemart_vpc.id

  # Allow PostgreSQL traffic from the EKS Cluster Security Group
  ingress {
    description = "Allow PostgreSQL from EKS Nodes"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    # CORRECTED REFERENCE: Uses the EKS Cluster's primary security group
    security_groups = [aws_eks_cluster.innovatemart_cluster.vpc_config[0].cluster_security_group_id] 
  }

  # Allow MySQL traffic from the EKS Cluster Security Group
  ingress {
    description = "Allow MySQL from EKS Nodes"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    # CORRECTED REFERENCE: Uses the EKS Cluster's primary security group
    security_groups = [aws_eks_cluster.innovatemart_cluster.vpc_config[0].cluster_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- 3. RDS PostgreSQL Instance (for Orders Service) ---
resource "aws_db_instance" "orders_db" {
  identifier           = "${var.cluster_name}-orders-db"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "16.10"
  username             = "orders"
  password             = random_password.rds_password.result
  db_subnet_group_name = aws_db_subnet_group.innovatemart_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = false
  depends_on = [aws_eks_cluster.innovatemart_cluster] 
}

# --- 4. RDS MySQL Instance (for Catalog Service) ---
resource "aws_db_instance" "catalog_db" {
  identifier           = "${var.cluster_name}-catalog-db"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0"
  username             = "catalog"
  password             = random_password.rds_password.result
  db_subnet_group_name = aws_db_subnet_group.innovatemart_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = false
  depends_on = [aws_eks_cluster.innovatemart_cluster]
}

# --- 5. DynamoDB Table (for Carts Service) ---
resource "aws_dynamodb_table" "carts_db" {
  name             = "${var.cluster_name}-carts"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "cartId"

  attribute {
    name = "cartId"
    type = "S"
  }
}