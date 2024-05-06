# Cloud Infrastructure Setup: Provisioning EKS, ALB and CloudFront with Terraform

This repository contains Terraform scripts to provision an Amazon Elastic Kubernetes Service (EKS) cluster, an Application Load Balancer (ALB), and a CloudFront distribution. These resources are provisioned in separate folders to maintain modularity and ease of management.

## Table of Contents

1. [Overview](#overview)
2. [Folder Structure](#folder-structure)
3. [Prerequisites](#prerequisites)
4. [Instructions](#instructions)
    - [Provisioning Steps](#provisioning-steps)

## Overview

### Task 1: Create a CloudFront Distribution

Using Terraform, provision a CloudFront distribution with the specified origin server (ALB) and any additional settings required for the specific use case.

### Task 2: Connect CloudFront Distribution to an ALB

Using Terraform, provision an ALB and configure it to handle incoming requests. Ensure proper security group settings for the ALB to allow traffic from CloudFront.

### Task 3: Deploy Kubernetes Cluster in eu-west-1

Utilize Terraform to deploy an Amazon EKS cluster in the eu-west-1 region. Choose a simple web server Docker image that runs a web server capable of receiving API requests.

## Folder Structure

- **1-eks**: Contains Terraform scripts to provision the EKS cluster.
- **2-cloudfront**: Contains Terraform scripts to provision the ALB and CloudFront distribution.

## Prerequisites

Before you begin, ensure you have the following installed:

1. **Terraform**: You can download it from [Terraform's official website](https://www.terraform.io/downloads.html).
   
2. **AWS CLI**: Install AWS Command Line Interface by following the instructions in the [AWS documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html).

3. **kubectl**: Install Kubernetes command-line tool by following the instructions in the [Kubernetes documentation](https://kubernetes.io/docs/tasks/tools/install-kubectl/).

## Instructions

### Provisioning Steps

1. Clone this repository to your local machine:

    ```bash
    git clone https://github.com/your-username/your-repo.git
    ```

2. Navigate to the `1-eks` folder for provisioning the EKS cluster and the ALB ingress:

    ```bash
    cd 1-eks
    ```

3. Initialize Terraform:

    ```bash
    terraform init
    ```

4. Review and modify `terraform.tfvars` file to customize your EKS configuration if needed.

5. Apply Terraform configuration:

    ```bash
    terraform apply -auto-approve
    ```

6. The terraform program will save in the "2-cloudfront/alb_hostname" the ALB host URL that will be used in the provisioning of the Cloudfront resource

7. Once the EKS cluster is provisioned successfully, navigate to the `2-cloudfront` folder to provision CloudFront:

    ```bash
    cd ../2-cloudfront
    ```

8. Initialize Terraform:

    ```bash
    terraform init
    ```

9. Review and modify `terraform.tfvars` file to customize your ALB and CloudFront configuration if needed.

10. Apply Terraform configuration:

    ```bash
    terraform apply -auto-approve
    ```

11. Once provisioning is complete, Terraform will output relevant information such as the URL of the CloudFront distribution.
