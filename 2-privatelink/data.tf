data "aws_availability_zones" "available" {}

data "local_file" "eks_vpc_private_subnet_id" {
  filename = "${path.module}/eks_vpc_private_subnet"
}

data "local_file" "eks_vpc_vpc_id" {
  filename = "${path.module}/eks_vpc_vpc_id"
}

data "terraform_remote_state" "eks_vpc" {
  backend = "s3"
  config = {
    bucket = "yanivzl-solitics-tfstate"
    key    = "state/1-eks.tfstate"
    region = "eu-west-1"
  }
}