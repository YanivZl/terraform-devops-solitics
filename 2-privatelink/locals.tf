locals {
  num_of_subnets = 1
  azs            = slice(data.aws_availability_zones.available.names, 0, local.num_of_subnets)

  producer_ec2_user_data = <<-EOT
    #!/bin/bash
    echo "Hello world from $(hostname)! This is the ec2 machine in the private subnet in the fully private vpc" > /var/www/html/index.html
  EOT

  tags = {
    Name        = var.name
    Environment = var.environment
  }
}