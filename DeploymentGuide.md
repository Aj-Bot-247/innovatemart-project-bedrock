# InnovateMart "Project Bedrock" - Deployment & Architecture Guide

This document provides an overview of the infrastructure architecture for Project Bedrock and includes instructions for accessing the deployed application and the EKS cluster.

---

## 1. Architecture Overview

The infrastructure for the InnovateMart Retail Store Application is provisioned entirely using Terraform and deployed via a GitHub Actions CI/CD pipeline. The final architecture reflects a production-grade setup, incorporating the bonus objectives for persistence and networking.

### Core Components
* **Networking**: A custom Virtual Private Cloud (VPC) with public and private subnets across two Availability Zones for high availability. A NAT Gateway in the public subnet allows resources in the private subnets (like our EKS nodes) to access the internet securely.
* **Compute**: An Amazon Elastic Kubernetes Service (EKS) cluster named `innovatemart-prod` serves as the container orchestration platform. The worker nodes are `t3.medium` instances running in an auto-scaling group within the private subnets.
* **CI/CD**: A GitHub Actions workflow automates the deployment of the Terraform infrastructure. The pipeline is triggered on pushes to the `main` branch, ensuring the infrastructure state is always in sync with the code in the repository.

### Bonus Objective Architecture
* **Managed Persistence Layer**: To ensure reliability and scalability, the application's in-cluster databases were replaced with managed AWS services. The **Orders service** uses **AWS RDS for PostgreSQL**, the **Catalog service** uses **AWS RDS for MySQL**, and the **Carts service** uses **Amazon DynamoDB**. Database credentials are securely managed via Kubernetes Secrets.
* **Public Access**: The application is exposed to the internet via an **Application Load Balancer (ALB)**, which is automatically provisioned and managed by the **AWS Load Balancer Controller** running in the cluster.

---

## 2. Accessing the Running Application

The application is publicly accessible via the DNS name of the Application Load Balancer.

1.  **Get the Application URL**: The public URL for the application can be retrieved by running the following command:
    ```bash
    kubectl get ingress -n innovatemart-app
    ```

2.  **Access in Browser**: Copy the value from the `ADDRESS` column in the output and paste it into your web browser.
    * **URL**: `http://<ALB_DNS_NAME>`
    * Example: `http://k8s-innovate-innovate-d464e03d82-1603065897.eu-west-1.elb.amazonaws.com`

---

## 3. Read-Only Developer Access

A dedicated IAM user, **`innovatemart-dev-readonly`**, has been created for the development team. This user has read-only permissions within the EKS cluster, allowing them to view logs, describe pods, and check service status without making changes.

### 3.1. Developer Credentials

* **AWS Access Key ID:** `<PASTE_developer_user_access_key_id_HERE>`
* **AWS Secret Access Key:** `<PASTE_developer_user_secret_access_key_HERE>`

### 3.2. Kubeconfig Instructions

To access the cluster, a developer must configure their local machine with the AWS CLI and `kubectl`.

1.  **Configure AWS CLI Profile**: Set up a new, named AWS CLI profile with the credentials provided above. This is a best practice to avoid conflicts with other AWS accounts.
    ```bash
    aws configure --profile innovatemart-developer
    # Enter the Access Key ID and Secret Access Key when prompted
    # Set the default region to eu-west-1
    ```

2.  **Update Kubeconfig**: Use the new profile to update your local Kubernetes configuration file (`~/.kube/config`) to grant access to the EKS cluster.
    ```bash
    aws eks update-kubeconfig --name innovatemart-prod --region eu-west-1 --profile innovatemart-developer
    ```

3.  **Verify Access**: Test your read-only access. Listing resources should succeed, while attempting to modify them will fail.
    ```bash
    # This command will succeed
    kubectl get pods -n innovatemart-app

    # This command will fail with a permissions error
    kubectl delete pod <some-pod-name> -n innovatemart-app
    ```

---

## 4. Bonus Objectives Implementation Details

### 4.1 Managed Persistence Layer
The `bonus-features` branch contains the implementation for using managed AWS databases.
* **Terraform**: A new `rds.tf` file was created to provision the RDS instances and the DynamoDB table.
* **Configuration**: A new `helm-values-bonus.yaml` file was used to disable the in-cluster database charts and inject the new RDS and DynamoDB endpoints as environment variables. Database passwords are not stored in Git; they are managed by a Kubernetes Secret (`rds-credentials`).

### 4.2 Advanced Networking & Security
The AWS Load Balancer Controller was installed via Helm and configured with a dedicated IAM Role for Service Accounts (IRSA). An Ingress resource (`ingress.yaml`) was created to provision the public ALB.

As per the project instructions, the process for enabling SSL/TLS was documented. The file `terraform/acm.tf` (now commented out) contains the complete Terraform code that would automatically provision an AWS Route 53 zone for a placeholder domain (`innovatemart-ajbot.com`), request an ACM certificate, and complete DNS validation. Because there is no SSL certificate, the Ingress is configured for **HTTP only**.