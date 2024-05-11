################################################################################
# VPC - Producer / Private
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "fully-private-vpc-${var.name}"
  cidr = var.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 4, k)]

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags
}

################################################################################
# First EC2 with TG - in Fully Private VPC
################################################################################

module "first_ec2_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name = "${var.name}-first-instance-producer"

  instance_type = "t2.micro"
  # Private AMI with already installed httpd server on it
  # Used to avoid using NAT Gateway for httpd installation - to ensure VPC fully private
  ami                    = "ami-0900a14cef39b5f14"
  subnet_id              = module.vpc.private_subnets[0]
  vpc_security_group_ids = [module.first_ec2_security_group_private_vpc.security_group_id]

  user_data_base64            = base64encode(local.producer_ec2_user_data)
  user_data_replace_on_change = true
}

module "first_ec2_security_group_private_vpc" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.name}-sg"
  description = "Allow http traffic (port 80) to Between EC2 I to EC2 II"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp"]

  tags = local.tags
}

resource "aws_lb_target_group" "tg_producer" {
  name     = "${var.name}-tg-producer"
  port     = 80
  protocol = "TCP"
  vpc_id   = module.vpc.vpc_id

  tags = local.tags
}

resource "aws_lb_target_group_attachment" "ec2_attachment_producer" {
  target_group_arn = aws_lb_target_group.tg_producer.arn
  target_id        = module.first_ec2_instance.id
  port             = 80
}

################################################################################
# NLB + VPC Endpoint Service - Enabling cnnectivity with the private subnet
################################################################################

resource "aws_lb" "yanivzl_nlb_producer" {
  name               = "${var.name}-nlb-producer"
  internal           = true
  load_balancer_type = "network"
  subnets            = module.vpc.private_subnets
  security_groups    = [module.first_ec2_security_group_private_vpc.security_group_id]
  tags               = local.tags
}

resource "aws_lb_listener" "yanivzl_full_private_ec2" {
  depends_on        = [aws_lb_target_group.tg_producer]
  load_balancer_arn = aws_lb.yanivzl_nlb_producer.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_producer.arn
  }

  tags = local.tags
}

resource "aws_vpc_endpoint_service" "yanivzl_nlb_producer_vpc_endpoint_service" {
  acceptance_required        = false
  network_load_balancer_arns = [aws_lb.yanivzl_nlb_producer.arn]

  tags = local.tags
}

################################################################################
# Second EC2 - in EKS VPC
################################################################################

module "second_ec2_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name = "${var.name}-second-instance-consumer"

  instance_type = "t2.micro"

  subnet_id              = data.terraform_remote_state.eks_vpc.outputs.eks_cluster_private_subnet_ids[0]
  vpc_security_group_ids = [module.second_ec2_security_group_eks_vpc.security_group_id]
}

module "second_ec2_security_group_eks_vpc" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.name}-sg-eks-vpc"
  description = "Allow http & shh traffic"
  vpc_id      = data.terraform_remote_state.eks_vpc.outputs.eks_cluster_vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "ssh-tcp"]

  egress_rules = ["http-80-tcp"]

  tags = local.tags
}

################################################################################
# VPC Endpoint Service
# Enabling connectivity from the private subnet of the EKS VPC
################################################################################

resource "aws_vpc_endpoint" "eks_vpc_endpoint" {
  service_name       = aws_vpc_endpoint_service.yanivzl_nlb_producer_vpc_endpoint_service.service_name
  subnet_ids         = [data.terraform_remote_state.eks_vpc.outputs.eks_cluster_private_subnet_ids.0]
  vpc_endpoint_type  = aws_vpc_endpoint_service.yanivzl_nlb_producer_vpc_endpoint_service.service_type
  vpc_id             = data.terraform_remote_state.eks_vpc.outputs.eks_cluster_vpc_id
  security_group_ids = [module.second_ec2_security_group_eks_vpc.security_group_id]
  tags               = local.tags
}

################################################################################
# EC2 Instance Connect Endpoint
# Enabling Connecting to the mchine in the EKS VPC private subnet
################################################################################


resource "aws_ec2_instance_connect_endpoint" "enable_connection_to_private_subnet" {
  subnet_id          = data.terraform_remote_state.eks_vpc.outputs.eks_cluster_private_subnet_ids.0
  security_group_ids = [module.second_ec2_security_group_eks_vpc.security_group_id]
  tags               = local.tags
}