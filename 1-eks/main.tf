################################################################################
# VPC
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 48)]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags
}


################################################################################
# Cluster
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name                             = var.cluster_name
  cluster_version                          = var.cluster_version
  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  create_cloudwatch_log_group = false

  eks_managed_node_groups = {
    gp-managed-node-group = {
      node_group_name = var.node_group_name
      instance_types  = ["t3.medium"]

      min_size     = var.node_group_min_size
      max_size     = var.node_group_max_size
      desired_size = var.node_group_desired_size
    }
  }

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  tags = local.tags
}

################################################################################
# EKS Blueprints Addons
################################################################################

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.16"

  depends_on = [module.eks]

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # Set up necessary IRSA for AWS Load Balancer Controller 
  enable_aws_load_balancer_controller = true
  # Deploy AWS Load Balancer Controller 
  aws_load_balancer_controller = {}

  helm_releases = {
    httpbin = {
      name       = "httpbin"
      repository = "https://matheusfm.dev/charts"
      chart      = "httpbin"

      set = [{
        name  = "service.type"
        value = "NodePort"
      }]
    }
  }
}

################################################################################
# ALB Ingress resource
################################################################################

resource "kubectl_manifest" "ingress" {
  depends_on = [module.eks_blueprints_addons]
  yaml_body  = file("${path.module}/alb-ingress.yaml")
}

resource "null_resource" "alb_hostname" {
  provisioner "local-exec" {
    command = "kubectl get ingress alb-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' > ../2-cloudfront/alb_hostname"
  }
}

