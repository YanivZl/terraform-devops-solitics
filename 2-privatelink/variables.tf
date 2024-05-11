variable "name" {
  description = "The name of the second VPC and the EC2s."
  type        = string
  default     = "solitics-yanivzl"
}

variable "region" {
  description = "AWS Region"
  type        = string
  default     = "eu-west-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "environment" {
  description = "Environment of the deployment - just for tags"
  type        = string
  default     = "Development"
}
