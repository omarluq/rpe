# NGINX Helm Chart

Production-ready Helm chart for deploying NGINX web server with Ingress support to Kubernetes/EKS.

✅ **Simple templated Helm chart** that loads an nginx server

✅ **Appropriate ingress** (supports both NGINX and ALB controllers)

✅ **values.yml file** with production-ready defaults

✅ **Template dump command** for manifest validation

✅ **GitHub Actions workflow** using OIDC for EKS deployment

## Template Validation Command

To dump the generated templates:

```bash
helm template my-nginx ./k8s/nginx-chart
```

### Additional Validation Commands

```bash
# Dump to file for review
helm template my-nginx ./k8s/nginx-chart > generated-manifests.yaml

# Validate specific template
helm template my-nginx ./k8s/nginx-chart -s templates/deployment.yaml

# Dry-run with debug output
helm install my-nginx ./k8s/nginx-chart --dry-run --debug

# Lint the chart
helm lint ./k8s/nginx-chart
```

## Features

This chart deploys a secure, highly-available NGINX web server with:

- **Production-ready security** - Non-root user, read-only filesystem, dropped capabilities
- **High availability** - 2 replicas with pod anti-affinity across nodes
- **Health monitoring** - Liveness and readiness probes
- **Resource management** - CPU and memory limits/requests
- **TLS support** - Automatic certificate management via cert-manager
- **Ingress flexibility** - Support for NGINX Ingress Controller and AWS ALB
- **Custom NGINX config** - ConfigMap-based configuration

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- Ingress controller (NGINX Ingress Controller or AWS Load Balancer Controller)
- cert-manager (optional, for automatic TLS certificates)

## Quick Start

### Basic Installation

```bash
helm install my-nginx ./k8s/nginx-chart
```

### Custom Installation

```bash
helm install my-nginx ./k8s/nginx-chart \
  --set ingress.hosts[0].host=myapp.example.com \
  --set ingress.tls[0].hosts[0]=myapp.example.com \
  --set replicaCount=3
```

### Installation with Custom Values File

Create `custom-values.yaml`:

```yaml
replicaCount: 3

ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: myapp.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: myapp-tls
      hosts:
        - myapp.example.com

resources:
  limits:
    cpu: 500m
    memory: 256Mi
  requests:
    cpu: 250m
    memory: 128Mi
```

Install:

```bash
helm install my-nginx ./k8s/nginx-chart -f custom-values.yaml
```

## Configuration Parameters

| Parameter                   | Description              | Default         |
| --------------------------- | ------------------------ | --------------- |
| `replicaCount`              | Number of NGINX replicas | `2`             |
| `image.repository`          | NGINX image repository   | `nginx`         |
| `image.tag`                 | NGINX image tag          | `1.29.3-alpine` |
| `image.pullPolicy`          | Image pull policy        | `IfNotPresent`  |
| `service.type`              | Kubernetes service type  | `ClusterIP`     |
| `service.port`              | Service port             | `80`            |
| `service.targetPort`        | Container target port    | `8080`          |
| `ingress.enabled`           | Enable ingress           | `true`          |
| `ingress.className`         | Ingress class name       | `nginx`         |
| `ingress.annotations`       | Ingress annotations      | See values.yaml |
| `resources.limits.cpu`      | CPU limit                | `200m`          |
| `resources.limits.memory`   | Memory limit             | `128Mi`         |
| `resources.requests.cpu`    | CPU request              | `100m`          |
| `resources.requests.memory` | Memory request           | `64Mi`          |

## Ingress Controller Configuration

### NGINX Ingress Controller

```yaml
ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
  hosts:
    - host: myapp.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: myapp-tls
      hosts:
        - myapp.example.com
```

### AWS Load Balancer Controller (ALB)

```yaml
ingress:
  enabled: true
  className: "alb"
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
    alb.ingress.kubernetes.io/ssl-redirect: "443"
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:region:account:certificate/id
  hosts:
    - host: myapp.example.com
      paths:
        - path: /
          pathType: Prefix
```

## Deployment to EKS Staging Cluster

### Manual Deployment

```bash
# 1. Validate the chart
helm lint ./k8s/nginx-chart
helm template staging ./k8s/nginx-chart

# 2. Install to staging namespace
helm install nginx-staging ./k8s/nginx-chart \
  --namespace staging \
  --create-namespace \
  --set ingress.hosts[0].host=staging.example.com \
  --set ingress.tls[0].hosts[0]=staging.example.com \
  --wait \
  --timeout 5m

# 3. Verify deployment
kubectl get all -n staging
kubectl get ingress -n staging

# 4. Check pod status
kubectl get pods -n staging -l app.kubernetes.io/name=nginx-chart
```

### Automated Deployment with GitHub Actions

The repository includes a GitHub Actions workflow (`.github/workflows/deploy-staging.yaml`) that:

- Uses **GitHub's OIDC provider** as a trusted AWS identity (no static credentials)
- Authenticates to AWS using temporary credentials
- Deploys the Helm chart to EKS staging cluster
- Runs automated verification and testing

**Trigger**: Push to `main` branch with changes to `k8s/nginx-chart/**`

**Setup Requirements**:

1. Configure AWS IAM OIDC provider for GitHub
2. Create IAM role with EKS permissions
3. Add GitHub repository secret `AWS_ROLE_ARN`
4. Configure EKS cluster access in aws-auth ConfigMap

See `.github/workflows/README.md` for complete OIDC setup instructions.

## Generated Kubernetes Resources

The chart generates the following resources:

1. **ConfigMap** - Custom NGINX configuration with security hardening
2. **Service** - ClusterIP service exposing port 80
3. **Deployment** - 2 replicas with security context and health checks
4. **Ingress** - HTTPS ingress with TLS support

## Architecture & Security

### Security Hardening

The chart implements production-grade security defaults:

```yaml
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 101
  fsGroup: 101
  seccompProfile:
    type: RuntimeDefault

securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 101
```

**Security Features**:

- ✅ Non-root user (UID 101)
- ✅ Read-only root filesystem
- ✅ All capabilities dropped
- ✅ No privilege escalation
- ✅ Seccomp profile enforced
- ✅ Resource limits enforced

### High Availability

Pod anti-affinity distributes replicas across nodes:

```yaml
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
              - key: app.kubernetes.io/name
                operator: In
                values:
                  - nginx-chart
          topologyKey: kubernetes.io/hostname
```

### Health Checks

Liveness and readiness probes ensure traffic routing to healthy pods:

```yaml
livenessProbe:
  httpGet:
    path: /
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```

### Read-Only Filesystem

EmptyDir volumes provide writable directories while keeping root filesystem read-only:

- `/var/cache/nginx` - NGINX cache directory
- `/var/run` - Runtime files and PID file

## Usage Examples

### Development Environment

```bash
helm install nginx-dev ./k8s/nginx-chart \
  --set replicaCount=1 \
  --set ingress.enabled=false \
  --set resources.limits.cpu=100m \
  --set resources.limits.memory=64Mi
```

### Production Environment

```bash
helm install nginx-prod ./k8s/nginx-chart \
  --namespace production \
  --create-namespace \
  --set replicaCount=3 \
  --set ingress.hosts[0].host=prod.example.com \
  --set resources.limits.cpu=500m \
  --set resources.limits.memory=256Mi
```

### EKS Staging with ALB

```bash
helm install nginx-staging ./k8s/nginx-chart \
  --namespace staging \
  --create-namespace \
  --set ingress.className=alb \
  --set ingress.annotations."alb\.ingress\.kubernetes\.io/scheme"=internet-facing \
  --set ingress.hosts[0].host=staging.example.com
```

## Upgrading & Maintenance

### Upgrade Release

```bash
helm upgrade nginx-staging ./k8s/nginx-chart -n staging
```

### Rollback Release

```bash
helm rollback nginx-staging -n staging
```

### Uninstall Release

```bash
helm uninstall nginx-staging -n staging
```

## Post-Deployment Verification

```bash
# Check deployment status
helm status nginx-staging -n staging

# View pod logs
kubectl logs -n staging -l app.kubernetes.io/name=nginx-chart

# Test connectivity via port-forward
kubectl port-forward -n staging svc/nginx-staging-nginx-chart 8080:80
curl http://localhost:8080

# Check ingress configuration
kubectl get ingress -n staging
kubectl describe ingress -n staging nginx-staging-nginx-chart

# Run Helm tests
helm test nginx-staging -n staging --logs
```

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -n staging -l app.kubernetes.io/name=nginx-chart
kubectl describe pod -n staging -l app.kubernetes.io/name=nginx-chart
```

### View Logs

```bash
kubectl logs -n staging -l app.kubernetes.io/name=nginx-chart
```

### Check Events

```bash
kubectl get events -n staging --sort-by='.lastTimestamp'
```

### Verify Resource Creation

```bash
kubectl get all,configmap,ingress -n staging
```

## Chart Structure

```
nginx-chart/
├── Chart.yaml              # Chart metadata (v1.0.0)
├── values.yaml             # Default configuration values
├── README.md               # This documentation
├── tests/
    ├── test-connection.yaml
└── templates/
    ├── _helpers.tpl        # Template helper functions
    ├── configmap.yaml      # NGINX configuration
    ├── deployment.yaml     # Deployment with security context
    ├── service.yaml        # ClusterIP service
    ├── ingress.yaml        # Ingress resource (NGINX/ALB)
    ├── NOTES.txt           # Post-installation notes
```

## Best Practices Implemented

1. ✅ **Resource limits specified** - Prevents resource exhaustion
2. ✅ **Pod anti-affinity configured** - High availability across nodes
3. ✅ **Ingress with TLS** - Secure external access
4. ✅ **Non-root execution** - Enhanced security posture
5. ✅ **Read-only root filesystem** - Prevents runtime tampering
6. ✅ **Health checks configured** - Ensures traffic to healthy pods only
7. ✅ **Specific image tags** - Reproducible deployments
8. ✅ **ConfigMap for configuration** - Externalized config management
9. ✅ **Standard Kubernetes labels** - Proper resource organization
10. ✅ **Helm tests included** - Post-deployment validation

## Additional Resources

- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [GitHub Actions OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
