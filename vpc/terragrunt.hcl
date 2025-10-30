# Terragrunt configuration for staging VPC module
# Terragrunt version: 0.91.4-1
# OpenTofu version: 1.10.6

# Configure Terragrunt to use OpenTofu
terraform_binary = "tofu"

# Configure the backend for state management
terraform {
  source = "."
}

# Remote state configuration (using local backend for validation)
# For production, replace with S3 backend configuration
remote_state {
  backend = "local"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    path = "terraform.tfstate"
  }
}

# Example S3 backend configuration (commented out):
# remote_state {
#   backend = "s3"
#   generate = {
#     path      = "backend.tf"
#     if_exists = "overwrite_terragrunt"
#   }
#   config = {
#     bucket         = "my-terraform-state-bucket"
#     key            = "vpc/staging/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "terraform-state-lock"
#   }
# }

# Generate provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = "staging"
      ManagedBy   = "terragrunt"
      Project     = "vpc-module"
    }
  }
}
EOF
}

# Input variables for the module
inputs = {
  vpc_name           = "staging-vpc"
  vpc_cidr           = "172.16.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]

  # Public subnets - AZ1 (us-east-1a)
  public_subnet_cidrs_az1 = [
    "172.16.0.0/20",  # Public subnet 1 in AZ1
    "172.16.16.0/20"  # Public subnet 2 in AZ1
  ]

  # Public subnets - AZ2 (us-east-1b)
  public_subnet_cidrs_az2 = [
    "172.16.64.0/20",  # Public subnet 1 in AZ2
    "172.16.80.0/20"   # Public subnet 2 in AZ2
  ]

  # Private subnets - AZ1 (us-east-1a)
  private_subnet_cidrs_az1 = [
    "172.16.32.0/20",  # Private subnet 1 in AZ1
    "172.16.48.0/20"   # Private subnet 2 in AZ1
  ]

  # Private subnets - AZ2 (us-east-1b)
  private_subnet_cidrs_az2 = [
    "172.16.96.0/20",   # Private subnet 1 in AZ2
    "172.16.112.0/20"   # Private subnet 2 in AZ2
  ]

  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_nat_gateway   = true

  tags = {
    Environment = "staging"
    Team        = "devops"
    CostCenter  = "engineering"
  }
}
