# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.main.arn
}

# Internet Gateway
output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

# Public Subnets
output "public_subnet_ids_az1" {
  description = "IDs of public subnets in AZ1"
  value       = aws_subnet.public_az1[*].id
}

output "public_subnet_ids_az2" {
  description = "IDs of public subnets in AZ2"
  value       = aws_subnet.public_az2[*].id
}

output "public_subnet_ids" {
  description = "IDs of all public subnets"
  value       = concat(aws_subnet.public_az1[*].id, aws_subnet.public_az2[*].id)
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of all public subnets"
  value = concat(
    aws_subnet.public_az1[*].cidr_block,
    aws_subnet.public_az2[*].cidr_block
  )
}

# Private Subnets
output "private_subnet_ids_az1" {
  description = "IDs of private subnets in AZ1"
  value       = aws_subnet.private_az1[*].id
}

output "private_subnet_ids_az2" {
  description = "IDs of private subnets in AZ2"
  value       = aws_subnet.private_az2[*].id
}

output "private_subnet_ids" {
  description = "IDs of all private subnets"
  value       = concat(aws_subnet.private_az1[*].id, aws_subnet.private_az2[*].id)
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of all private subnets"
  value = concat(
    aws_subnet.private_az1[*].cidr_block,
    aws_subnet.private_az2[*].cidr_block
  )
}

# NAT Gateways
output "nat_gateway_ids" {
  description = "IDs of NAT Gateways"
  value = var.enable_nat_gateway ? concat(
    aws_nat_gateway.az1[*].id,
    aws_nat_gateway.az2[*].id
  ) : []
}

output "nat_gateway_public_ips" {
  description = "Public IPs of NAT Gateways"
  value = var.enable_nat_gateway ? concat(
    aws_eip.nat_az1[*].public_ip,
    aws_eip.nat_az2[*].public_ip
  ) : []
}

# Route Tables
output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "IDs of private route tables"
  value       = [aws_route_table.private_az1.id, aws_route_table.private_az2.id]
}

# VPC Endpoints
output "s3_endpoint_id" {
  description = "ID of the S3 VPC endpoint"
  value       = aws_vpc_endpoint.s3.id
}

output "ssm_endpoint_id" {
  description = "ID of the SSM VPC endpoint"
  value       = aws_vpc_endpoint.ssm.id
}

output "ssm_endpoint_dns_entries" {
  description = "DNS entries for SSM endpoint"
  value       = aws_vpc_endpoint.ssm.dns_entry
}

output "vpc_endpoint_security_group_id" {
  description = "ID of the VPC endpoints security group"
  value       = aws_security_group.vpc_endpoints.id
}

# Availability Zones
output "availability_zones" {
  description = "Availability zones used"
  value       = var.availability_zones
}
