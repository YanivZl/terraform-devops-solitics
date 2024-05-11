terraform {
  required_version = ">= 1.3"

  backend "s3" {
    bucket  = "yanivzl-solitics-tfstate"
    key     = "state/3-privatelink.tfstate"
    region  = "eu-west-1"
    encrypt = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.48"
    }
  }
}