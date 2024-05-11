output "connect_to_ec2_command" {
    description = "Use this command to connect from your machine to the EC2 in the EKS VPC"
    value = "aws ec2-instance-connect ssh --instance-id ${module.second_ec2_instance.id} --region ${var.region}"
}

output "dns_entry_to_curl_to" {
  description = "The endpoint to use to connect to the VPC"
  value = aws_vpc_endpoint.eks_vpc_endpoint.dns_entry.0
}
