# Project Bedrock: Deployment & Architecture Guide

## 1. Architecture Overview

This project provisions a production-grade infrastructure on AWS for the InnovateMart retail application using Terraform and a CI/CD pipeline with GitHub Actions.

* **VPC:** A custom Virtual Private Cloud with public and private subnets across two availability zones for high availability and security.
* **EKS Cluster:** A managed Amazon EKS cluster named `innovatemart-prod` serves as the container orchestration platform.
* **Node Group:** A managed node group of `t3.medium` instances provides the compute capacity for the application pods.
* **CI/CD Pipeline:** A GitHub Actions workflow automates the `terraform apply` process upon every push to the `main` branch, ensuring the infrastructure state is always aligned with the code.
* **Application:** The `retail-store-sample-app` is deployed via Kubernetes manifests into the `retail` namespace. For this core deployment, all dependencies (MySQL, PostgreSQL, etc.) run as stateful containers within the cluster, using EBS volumes for persistent storage provisioned by the EBS CSI driver and a custom `gp3` StorageClass.

## 2. Accessing the Application

The application UI is exposed internally within the cluster. To access it for development or verification, use `kubectl port-forward`.

1.  **Get the UI pod name:**
    ```sh
    kubectl get pods -n retail -l app=ui -o jsonpath='{.items[0].metadata.name}'
    ```
2.  **Forward the port:** (Replace `[POD_NAME]` with the output from the command above)
    ```sh
    kubectl port-forward -n retail [POD_NAME] 8080:8080
    ```
3.  **Open in browser:** Navigate to `http://localhost:8080` in your web browser to view the application.

## 3. Read-Only Developer Access

A dedicated IAM user (`innovatemart-dev-readonly`) has been created for the development team, with permissions mapped via the `aws-auth` ConfigMap and Kubernetes RBAC to provide read-only access to cluster resources.

### 3.1. Developer Credentials

* **AWS Access Key ID:** `[Retrieve via 'terraform output -raw developer_user_access_key_id']`
* **AWS Secret Access Key:** `[Retrieve via 'terraform output -raw developer_user_secret_access_key']`

### 3.2. Kubeconfig Instructions

To configure `kubectl`, the developer must:

1.  **Install the AWS CLI** and configure it with the credentials provided above.
    ```sh
    aws configure
    ```
2.  **Update their Kubeconfig file** to connect to the EKS cluster.
    ```sh
    aws eks update-kubeconfig --name innovatemart-prod --region eu-west-1
    ```
3.  **Verify access.** Read-only commands will succeed, while write commands will be denied.
    ```sh
    # This will work
    kubectl get pods --all-namespaces

    # This will fail with a permissions error
    kubectl delete pod [some-pod-name] -n retail
    ```