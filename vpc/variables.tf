variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "staging-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "172.16.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs_az1" {
  description = "CIDR blocks for public subnets in AZ1"
  type        = list(string)
  default     = ["172.16.0.0/20", "172.16.16.0/20"]
}

variable "public_subnet_cidrs_az2" {
  description = "CIDR blocks for public subnets in AZ2"
  type        = list(string)
  default     = ["172.16.64.0/20", "172.16.80.0/20"]
}

variable "private_subnet_cidrs_az1" {
  description = "CIDR blocks for private subnets in AZ1"
  type        = list(string)
  default     = ["172.16.32.0/20", "172.16.48.0/20"]
}

variable "private_subnet_cidrs_az2" {
  description = "CIDR blocks for private subnets in AZ2"
  type        = list(string)
  default     = ["172.16.96.0/20", "172.16.112.0/20"]
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateways for private subnets"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
