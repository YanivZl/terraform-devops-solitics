# Solitics DevOps Interview Task

This repository contains the Terraform scripts and configurations used to set up cloud infrastructure and networking as per the provided tasks.

## Repository Structure

The repository is organized into two folders:

1. `1-eks`: Contains Terraform scripts to deploy an Amazon Elastic Kubernetes Service (EKS) cluster, Application load Balancer (ALB) in the eu-west-1 region and CloudFront distribution.
2. `2-privatelink`: Contains Terraform scripts to establish VPC connectivity between two VPCs via VPC private link.

## Prerequisites

Before you begin, ensure you have the following installed:

1. **Terraform**: You can download it from [Terraform's official website](https://www.terraform.io/downloads.html).
   
2. **AWS CLI**: Install AWS Command Line Interface by following the instructions in the [AWS documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html).

3. **kubectl**: Install Kubernetes command-line tool by following the instructions in the [Kubernetes documentation](https://kubernetes.io/docs/tasks/tools/install-kubectl/).

## Task Description

### Cloud Infrastructure Setup

#### Task 1: Create a CloudFront Distribution

Using Terraform, we provisioned a CloudFront distribution and specified the origin server as an Application Load Balancer (ALB). Additional settings were configured as per our specific use case.

#### Task 2: Connect CloudFront Distribution to an ALB

Using Terraform, an ALB was provisioned and configured to handle incoming requests. Proper security group settings were applied to the ALB to allow traffic from CloudFront.

#### Task 3: Deploy Kubernetes Cluster in eu-west-1

We utilized Terraform to deploy an Amazon Elastic Kubernetes Service (EKS) cluster in the eu-west-1 region. A simple web server Docker image was chosen to run a web server capable of receiving API requests.

### Networking Configuration

#### Task: Establish VPC Connectivity

Connectivity between two VPCs was established using VPC private link or Transit Gateway (TGW). EC2 instances were created in each VPC, and connectivity was verified using tools like netcat, telnet, or other suitable methods to ensure the network is correctly configured.

## Usage

To deploy the infrastructure:

1. Clone this repository.
2. Navigate to the `1-eks` directory.
3. Run `terraform init` to initialize the working directory.
4. Run `terraform apply` to apply the Terraform configuration and provision the EKS cluster.
5. After the EKS cluster is successfully deployed, navigate to the `2-privatelink` directory.
6. Run `terraform init` to initialize the working directory.
7. Run `terraform apply` to apply the Terraform configuration and establish VPC connectivity via VPC private link.
8. After deployment, verify the setup using appropriate tools and methods.

## Solution Description

### Task 1: Provisioning EKS, ALB and CloudFront Distribution

Using Terraform, we provisioned an Amazon Elastic Kubernetes Service (EKS) cluster in the eu-west-1 region. The EKS cluster includes a simple web server application (e.g., httpbin) deployed as a Docker container.

The EKS cluster is configured to manage incoming HTTP traffic using an Application Load Balancer (ALB) provisioned as an ingress resource. This ALB acts as the entry point for external traffic to the Kubernetes services running in the cluster.

Additionally, a CloudFront distribution was set up with the ALB as the origin server. This configuration allows CloudFront to cache content from the EKS cluster, improving content delivery performance and scalability.

The CloudFront distribution is configured with logging enabled. Logs generated by CloudFront are sent to an Amazon S3 bucket for storage and analysis. This logging system provides valuable insights into the usage and performance of the CloudFront distribution.

The CloudFront URL that provisioned and accessible is: `http://d3769gua5fx0le.cloudfront.net/`. The application deployed is similar to [httpbingo.org](https://httpbingo.org/).

### Task 2: Establish VPC Connectivity via VPC PrivateLink

The `2-privatelink` folder contains Terraform scripts to establish VPC connectivity between two VPCs using VPC private link. It utilizes the VPC created in Task 1 (`eks-vpc`).

The deployment includes:

- Deployment of an EC2 instance within the `eks-vpc`.
- Creation of a VPC endpoint within `eks-vpc` to enable private connectivity to services within another VPC.
- Deployment of another VPC with a single private subnet.
- Provisioning of an EC2 instance within the second VPC using a predefined custom AMI. The custom AMI has an HTTP server (e.g., httpd) installed on it to avoid the usage of NAT Gateway, ensuring that the VPC remains fully private.
- Creation of a VPC endpoint service to expose a service privately within the second VPC.

### Testing the Setup

To test the setup:

1. Connect to the EC2 instance within the `eks-vpc` private subnet using the `interview_user` account credentials and AWS CLI. Use the following command:
    ```bash
    aws ec2-instance-connect ssh --instance-id i-01883e0ef39f14dd1 --region eu-west-1
    ```

2. After connecting to the EC2 instance, send a `curl` request to the EC2 instance in the fully private VPC using the VPC endpoint service URL. Use the following command:
    ```bash
    curl vpce-0cad2282bf6c2269d-a6ytthfx.vpce-svc-0dbea7c0b3c436e1b.eu-west-1.vpce.amazonaws.com
    ```

This setup ensures secure and private communication between the two VPCs, and the testing steps verify the successful establishment of connectivity.