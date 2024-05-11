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

resource "kubernetes_ingress_v1" "alb_ingress" {
  metadata {
    name      = "alb-ingress"
    namespace = "default"
    annotations = {
      "alb.ingress.kubernetes.io/scheme" : "internet-facing"
      "alb.ingress.kubernetes.io/target-type" : "ip"
    }
  }
  spec {
    ingress_class_name = "alb"
    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "httpbin"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

################################################################################
# S3 bucket for CloudFront logs
################################################################################

resource "aws_s3_bucket" "cloudfront_logs" {
  bucket        = "cloudfront-logs-${var.cluster_name}"
  force_destroy = true

  tags = {
    Name        = "Cloudfront_Logs"
    Environment = "Development"
  }
}

resource "aws_s3_bucket_ownership_controls" "s3_bucket_acl_ownership" {
  bucket = aws_s3_bucket.cloudfront_logs.id
  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_acl" "eks-acl" {
  depends_on = [aws_s3_bucket_ownership_controls.s3_bucket_acl_ownership]
  bucket     = aws_s3_bucket.cloudfront_logs.id
  acl        = "private"
}

################################################################################
# CloudFront
################################################################################

module "cloudfront" {
  depends_on = [kubernetes_ingress_v1.alb_ingress]
  source     = "terraform-aws-modules/cloudfront/aws"

  enabled             = true
  price_class         = "PriceClass_100"
  retain_on_delete    = false
  wait_for_deployment = false

  create_monitoring_subscription = false

  logging_config = {
    bucket = aws_s3_bucket.cloudfront_logs.bucket_domain_name
    prefix = "cloudfront"
  }

  origin = {
    eks = {
      domain_name = kubernetes_ingress_v1.alb_ingress.status.0.load_balancer.0.ingress.0.hostname
      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "http-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  default_cache_behavior = {
    target_origin_id       = "eks"
    viewer_protocol_policy = "allow-all"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    query_string           = true

    # This is id for SecurityHeadersPolicy copied from https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-response-headers-policies.html
    response_headers_policy_id = "67f7725c-6f97-4210-82d7-5512b31e9d03"
  }
}

