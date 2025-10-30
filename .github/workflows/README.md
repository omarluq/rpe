# GitHub Actions Deployment Workflows

This directory contains GitHub Actions workflows for automated deployment to AWS EKS using OIDC authentication.

## OIDC Authentication Setup

GitHub Actions uses OpenID Connect (OIDC) to authenticate with AWS without storing long-lived credentials.

### Prerequisites

1. AWS Account with EKS cluster
2. GitHub repository
3. Permissions to create IAM roles and policies

### AWS IAM Configuration

#### 1. Create OIDC Identity Provider

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

#### 2. Create IAM Policy

Create a policy with necessary EKS permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["eks:DescribeCluster", "eks:ListClusters"],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": ["sts:AssumeRole"],
      "Resource": "*"
    }
  ]
}
```

Save as `github-actions-eks-policy.json` and create:

```bash
aws iam create-policy \
  --policy-name GitHubActionsEKSPolicy \
  --policy-document file://github-actions-eks-policy.json
```

#### 3. Create IAM Role for GitHub Actions

Create trust policy for GitHub OIDC:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:GITHUB_ORG/REPO_NAME:*"
        }
      }
    }
  ]
}
```

Replace:

- `ACCOUNT_ID` with your AWS account ID
- `GITHUB_ORG` with your GitHub organization or username
- `REPO_NAME` with your repository name

Create the role:

```bash
aws iam create-role \
  --role-name GitHubActionsEKSRole \
  --assume-role-policy-document file://trust-policy.json

aws iam attach-role-policy \
  --role-name GitHubActionsEKSRole \
  --policy-arn arn:aws:iam::ACCOUNT_ID:policy/GitHubActionsEKSPolicy
```

#### 4. Configure EKS Access

Add the GitHub Actions role to EKS aws-auth ConfigMap:

```bash
kubectl edit configmap aws-auth -n kube-system
```

Add under `mapRoles`:

```yaml
- rolearn: arn:aws:iam::ACCOUNT_ID:role/GitHubActionsEKSRole
  username: github-actions
  groups:
    - system:masters
```

### GitHub Secrets Configuration

Add the following secrets to your GitHub repository:

1. Go to repository **Settings** → **Secrets and variables** → **Actions**
2. Add new repository secret:
   - **Name**: `AWS_ROLE_ARN`
   - **Value**: `arn:aws:iam::ACCOUNT_ID:role/GitHubActionsEKSRole`

### Environment Configuration

Create a staging environment in GitHub:

1. Go to repository **Settings** → **Environments**
2. Create new environment: `staging`
3. (Optional) Add protection rules for approvals

## Workflow Overview

### `deploy-staging.yaml`

Deploys the NGINX Helm chart to EKS staging cluster.

**Trigger**: Push to `main` branch with changes to `k8s/nginx-chart/**`

**Steps**:

1. Checkout code
2. Authenticate to AWS using OIDC
3. Configure kubectl for EKS cluster
4. Setup Helm
5. Lint Helm chart
6. Deploy chart to staging namespace
7. Verify deployment
8. Run Helm tests

**Environment Variables**:

- `AWS_REGION`: AWS region (default: us-east-1)
- `EKS_CLUSTER_NAME`: Name of EKS cluster
- `HELM_CHART_PATH`: Path to Helm chart
- `NAMESPACE`: Kubernetes namespace
- `RELEASE_NAME`: Helm release name

## Testing Locally

Test the workflow locally using [act](https://github.com/nektos/act):

```bash
# Install act
yay -S act  # Arch Linux
# or
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Run workflow
act -W .github/workflows/deploy-staging.yaml
```

## Troubleshooting

### OIDC Authentication Fails

**Error**: `Not authorized to perform sts:AssumeRoleWithWebIdentity`

**Solution**:

- Verify OIDC provider is created in AWS
- Check trust policy includes correct repository
- Ensure `id-token: write` permission in workflow

### EKS Access Denied

**Error**: `You must be logged in to the server (Unauthorized)`

**Solution**:

- Verify IAM role is added to aws-auth ConfigMap
- Check EKS cluster name and region are correct
- Ensure role has necessary EKS permissions

### Helm Deployment Fails

**Error**: `Error: INSTALLATION FAILED`

**Solution**:

- Check namespace exists
- Verify Helm chart syntax with `helm lint`
- Review pod logs: `kubectl logs -n staging -l app.kubernetes.io/name=nginx-chart`

## References

- [GitHub OIDC Documentation](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [AWS IAM OIDC](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
- [EKS Access Management](https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html)
