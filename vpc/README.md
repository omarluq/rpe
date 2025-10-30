# AWS VPC Terraform Module

Production-ready Terraform module for creating a highly-available VPC in AWS with proper network segmentation, NAT gateways, and VPC endpoints.

## Features

- **Multi-AZ High Availability**: 2 availability zones with redundant networking
- **Network Segmentation**: 8 subnets (4 public + 4 private across 2 AZs)
- **VPC Endpoints**: Internal endpoints for SSM and S3 (no internet required)
- **NAT Gateways**: Redundant NAT gateways (one per AZ) for private subnet internet access
- **Internet Gateway**: Public subnet internet connectivity
- **Route Tables**: Properly configured routing for public and private subnets
- **Security Groups**: Security group for VPC endpoint access
- **Terragrunt Compatible**: Ready to use with Terragrunt orchestration

## Requirements

- **OpenTofu**: >= 1.10.0 (tested with 1.10.6)
- **Terragrunt**: >= 0.91.0 (tested with 0.91.4-1)
- **AWS Provider**: ~> 5.92

## Architecture

### Network Layout

```
VPC: 172.16.0.0/16

Availability Zone 1 (us-east-1a):
  Public Subnet 1:  172.16.0.0/20   (4,094 IPs)
  Public Subnet 2:  172.16.16.0/20  (4,094 IPs)
  Private Subnet 1: 172.16.32.0/20  (4,094 IPs)
  Private Subnet 2: 172.16.48.0/20  (4,094 IPs)

Availability Zone 2 (us-east-1b):
  Public Subnet 1:  172.16.64.0/20  (4,094 IPs)
  Public Subnet 2:  172.16.80.0/20  (4,094 IPs)
  Private Subnet 1: 172.16.96.0/20  (4,094 IPs)
  Private Subnet 2: 172.16.112.0/20 (4,094 IPs)
```

### Components

1. **VPC** - Main virtual private cloud with 172.16.0.0/16 CIDR
2. **Internet Gateway** - Public internet access for public subnets
3. **NAT Gateways (2)** - One per AZ for private subnet outbound internet
4. **Public Subnets (4)** - 2 per AZ, route to Internet Gateway
5. **Private Subnets (4)** - 2 per AZ, route to NAT Gateway
6. **Route Tables (3)** - 1 public, 2 private (one per AZ)
7. **VPC Endpoints**:
   - **S3 Gateway Endpoint** - Direct access to S3 without internet
   - **SSM Interface Endpoint** - AWS Systems Manager access
   - **SSM Messages Endpoint** - SSM Session Manager support
   - **EC2 Messages Endpoint** - Required for SSM functionality

## Usage

### Using with Terragrunt

1. **Update the terragrunt.hcl configuration**:

```hcl
# Configure the S3 backend
remote_state {
  backend = "s3"
  config = {
    bucket         = "your-terraform-state-bucket"
    key            = "vpc/staging/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "your-terraform-lock-table"
  }
}

# Customize inputs
inputs = {
  vpc_name           = "my-staging-vpc"
  vpc_cidr           = "172.16.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]

  tags = {
    Environment = "staging"
    Team        = "devops"
  }
}
```

2. **Initialize and apply with Terragrunt**:

```bash
# Initialize
terragrunt init

# Plan
terragrunt plan

# Apply
terragrunt apply

# Show outputs
terragrunt output
```

### Using with OpenTofu Directly

1. **Create a terraform.tfvars file**:

```hcl
vpc_name           = "staging-vpc"
vpc_cidr           = "172.16.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]

tags = {
  Environment = "staging"
  Team        = "devops"
}
```

2. **Initialize and apply**:

```bash
# Initialize
tofu init

# Plan
tofu plan

# Apply
tofu apply

# Show outputs
tofu output
```

## Input Variables

| Variable                   | Description                 | Type           | Default                        | Required |
| -------------------------- | --------------------------- | -------------- | ------------------------------ | -------- |
| `vpc_name`                 | Name of the VPC             | `string`       | `"staging-vpc"`                | no       |
| `vpc_cidr`                 | CIDR block for the VPC      | `string`       | `"172.16.0.0/16"`              | no       |
| `availability_zones`       | List of availability zones  | `list(string)` | `["us-east-1a", "us-east-1b"]` | no       |
| `public_subnet_cidrs_az1`  | Public subnet CIDRs in AZ1  | `list(string)` | See below                      | no       |
| `public_subnet_cidrs_az2`  | Public subnet CIDRs in AZ2  | `list(string)` | See below                      | no       |
| `private_subnet_cidrs_az1` | Private subnet CIDRs in AZ1 | `list(string)` | See below                      | no       |
| `private_subnet_cidrs_az2` | Private subnet CIDRs in AZ2 | `list(string)` | See below                      | no       |
| `enable_dns_hostnames`     | Enable DNS hostnames        | `bool`         | `true`                         | no       |
| `enable_dns_support`       | Enable DNS support          | `bool`         | `true`                         | no       |
| `enable_nat_gateway`       | Enable NAT Gateways         | `bool`         | `true`                         | no       |
| `tags`                     | Additional tags             | `map(string)`  | `{}`                           | no       |

### Default Subnet CIDRs

```hcl
public_subnet_cidrs_az1  = ["172.16.0.0/20", "172.16.16.0/20"]
public_subnet_cidrs_az2  = ["172.16.64.0/20", "172.16.80.0/20"]
private_subnet_cidrs_az1 = ["172.16.32.0/20", "172.16.48.0/20"]
private_subnet_cidrs_az2 = ["172.16.96.0/20", "172.16.112.0/20"]
```

## Outputs

| Output                           | Description                         |
| -------------------------------- | ----------------------------------- |
| `vpc_id`                         | ID of the VPC                       |
| `vpc_cidr`                       | CIDR block of the VPC               |
| `vpc_arn`                        | ARN of the VPC                      |
| `internet_gateway_id`            | ID of the Internet Gateway          |
| `public_subnet_ids`              | IDs of all public subnets           |
| `private_subnet_ids`             | IDs of all private subnets          |
| `public_subnet_ids_az1`          | IDs of public subnets in AZ1        |
| `public_subnet_ids_az2`          | IDs of public subnets in AZ2        |
| `private_subnet_ids_az1`         | IDs of private subnets in AZ1       |
| `private_subnet_ids_az2`         | IDs of private subnets in AZ2       |
| `nat_gateway_ids`                | IDs of NAT Gateways                 |
| `nat_gateway_public_ips`         | Public IPs of NAT Gateways          |
| `public_route_table_id`          | ID of the public route table        |
| `private_route_table_ids`        | IDs of private route tables         |
| `s3_endpoint_id`                 | ID of the S3 VPC endpoint           |
| `ssm_endpoint_id`                | ID of the SSM VPC endpoint          |
| `vpc_endpoint_security_group_id` | Security group ID for VPC endpoints |
| `availability_zones`             | Availability zones used             |

## Design Decisions

### Subnet Sizing

Each subnet uses /20 CIDR blocks providing **4,094 usable IP addresses** per subnet. This provides ample room for growth while maintaining clean network segmentation.

### NAT Gateway Redundancy

Two NAT Gateways (one per AZ) ensure high availability. If one AZ fails, resources in the other AZ maintain internet connectivity.

### VPC Endpoints

- **S3 Gateway Endpoint**: Free, provides direct S3 access without NAT gateway costs
- **SSM Interface Endpoints**: Enable AWS Systems Manager access for EC2 instances without public IPs or bastion hosts
- All interface endpoints placed in private subnets for security

### Route Table Design

- **Public Route Table**: Single route table shared by all public subnets (0.0.0.0/0 ’ IGW)
- **Private Route Tables**: Separate route table per AZ (0.0.0.0/0 ’ NAT Gateway in same AZ)

This design ensures traffic stays within the same AZ when possible, reducing cross-AZ data transfer costs.

## Cost Considerations

Monthly AWS costs (us-east-1 region):

- **VPC**: Free
- **Internet Gateway**: Free
- **NAT Gateways**: ~$65/month ($32.50 per NAT × 2)
- **S3 Gateway Endpoint**: Free
- **SSM Interface Endpoints**: ~$21/month ($7 per endpoint × 3)
- **Data Transfer**: Variable based on usage

**Total Base Cost**: ~$86/month (excludes data transfer)

### Cost Optimization Options

To disable NAT Gateways (saves ~$65/month):

```hcl
inputs = {
  enable_nat_gateway = false
}
```

**Note**: This removes internet access from private subnets.

## Security Considerations

### Network Segmentation

- Public subnets: Resources requiring direct internet access (load balancers, NAT gateways)
- Private subnets: Application servers, databases (no direct internet access)

### VPC Endpoint Security

- Interface endpoints use security group allowing HTTPS (443) only from VPC CIDR
- Gateway endpoint (S3) integrated with route tables (no security group needed)

### Best Practices Implemented

- DNS support and hostnames enabled for proper name resolution
- Multiple AZs for high availability
- NAT gateways in public subnets for private subnet internet access
- VPC endpoints for AWS service access without internet
- Proper tagging for resource management and cost allocation

## Validation

### Validate Configuration

```bash
# Format code
tofu fmt

# Validate syntax
tofu validate

# Check with tflint (if installed)
tflint
```

### Test Deployment

```bash
# Plan without applying
terragrunt plan

# Apply with auto-approve (use with caution)
terragrunt apply -auto-approve
```

## Cleanup

To destroy all resources:

```bash
# With Terragrunt
terragrunt destroy

# With OpenTofu
tofu destroy
```

**Warning**: This will permanently delete the VPC and all associated resources.

## Module Structure

```
vpc/
  main.tf           # VPC, subnets, gateways, route tables
  endpoints.tf      # VPC endpoints and security groups
  variables.tf      # Input variable definitions
  outputs.tf        # Output value definitions
  versions.tf       # Provider version constraints
  terragrunt.hcl    # Terragrunt configuration example
  README.md         # This file
```

## References

- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [AWS VPC Endpoints](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints.html)
- [OpenTofu Documentation](https://opentofu.org/docs/)
- [Terragrunt Documentation](https://terragrunt.gruntwork.io/)
