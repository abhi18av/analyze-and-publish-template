# Infrastructure

This directory contains all infrastructure-as-code (IaC) configurations, automation scripts, and deployment tools for the project. The infrastructure is designed to be modular, scalable, and environment-agnostic.

## 🏗️ Architecture Overview

Our infrastructure follows a multi-layered approach built on **Canonical** and **HashiCorp** open-source foundations:

## 🏗️ **Canonical Stack**
- **Juju**: Application lifecycle management and service orchestration
- **MicroK8s**: Lightweight Kubernetes for development and edge
- **LXD**: System containers for efficient resource utilization
- **Multipass**: Ubuntu VMs for rapid development environments
- **Ubuntu**: Base OS across all deployments
- **Snapcraft**: Application packaging and distribution
- **Chiseled**: Trimming containers https://ubuntu.com/containers/chiseled
- **Rockcraft**: ...

## ⚡ **HashiCorp Stack**
- **Terraform**: Infrastructure as Code for all cloud providers
- **Vault**: Secrets management and encryption
- **Consul**: Service discovery and configuration
- **Nomad**: Workload orchestration for containers and VMs
- **Packer**: Automated image building
- **Waypoint**: Application deployment and lifecycle

## 🔄 **Integrated Architecture**
- **Provisioning**: Terraform + Packer for infrastructure and images
- **Runtime**: Juju + Nomad for application orchestration
- **Security**: Vault + Ubuntu Pro for secrets and compliance
- **Networking**: Consul + MicroK8s for service mesh and discovery
- **Development**: Multipass + LXD for local environments

## 📁 Directory Structure

```
infrastructure/
├── README.md                    # This file
├── config/                     # Centralized configuration
├── automations/                # Automation scripts
├── dagger/                     # Dagger CI/CD pipelines
├── terraform/                  # Infrastructure as Code
├── juju/                      # Juju charms and bundles
├── kubernetes/                # K8s manifests and Helm charts
├── packer/                    # Image building
├── virtualization/            # Container and VM configs
├── monitoring/                # Observability stack
├── security/                  # Security policies and scanning
├── testing/                   # Infrastructure tests
└── scripts/                   # Utility scripts
```

## 🚀 Quick Start

### Prerequisites

Ensure you have the following tools installed:

```bash
# Core tools
brew install terraform juju multipass docker
brew install --cask docker

# Optional tools
brew install packer helm kubectl
pip install dagger-io
```

### Environment Setup

1. **Choose your environment**:
   - `local` - Local development with Multipass/Docker
   - `cloud` - Cloud deployment (OCI/AWS)
   - `hybrid` - Mixed local/cloud setup

2. **Initialize configuration**:
   ```bash
   # Copy and customize environment config
   cp config/environments/local.example.yaml config/environments/local.yaml
   # Edit the file with your specific values
   ```

3. **Deploy infrastructure**:
   ```bash
   # Using just (recommended)
   just infrastructure-setup local
   
   # Or manually
   cd terraform/local-multipass-vm
   terraform init && terraform apply
   ```

## 🛠️ Tool-Specific Guides

### Terraform
- **Purpose**: Infrastructure provisioning and management
- **Supported Providers**: OCI, AWS, Local (Multipass), Docker
- **Usage**: See [terraform/README.md](terraform/README.md)

### Juju
- **Purpose**: Application deployment and lifecycle management
- **Supported Clouds**: Local, Kubernetes, Public clouds
- **Usage**: See [juju/README.md](juju/README.md)

### Dagger
- **Purpose**: CI/CD pipeline automation
- **Features**: Container-based builds, multi-language support
- **Usage**: See [dagger/README.md](dagger/README.md)

### Kubernetes
- **Purpose**: Container orchestration
- **Features**: Helm charts, Kustomize overlays, monitoring
- **Usage**: See [kubernetes/README.md](kubernetes/README.md)

## 🌍 Environment Management

### Local Development
- **Multipass VMs**: Lightweight Ubuntu VMs for testing
- **Docker Compose**: Local service orchestration
- **LXD**: System containers for isolation

### Cloud Deployment
- **OCI**: Oracle Cloud Infrastructure with free tier support
- **AWS**: Amazon Web Services integration
- **Multi-cloud**: Portable configurations across providers

### Hybrid Setup
- **Local + Cloud**: Development locally, deploy to cloud
- **Edge Computing**: Distributed workloads across locations

## 🔧 Common Tasks

### Infrastructure Lifecycle
```bash
# Initialize new environment
just infrastructure-init <environment>

# Deploy infrastructure
just infrastructure-deploy <environment>

# Update infrastructure
just infrastructure-update <environment>

# Destroy infrastructure
just infrastructure-destroy <environment>
```

### Application Deployment
```bash
# Deploy with Juju
just juju-deploy <bundle> <environment>

# Deploy to Kubernetes
just k8s-deploy <app> <environment>

# Deploy with Nomad
just nomad-deploy <job> <environment>
```

### Monitoring and Maintenance
```bash
# Check infrastructure health
just infrastructure-health <environment>

# View logs
just infrastructure-logs <environment> <service>

# Run security scan
just security-scan <environment>
```

## 🔍 Troubleshooting

### Common Issues

**Terraform State Lock**
```bash
# Force unlock (use carefully)
terraform force-unlock <lock-id>
```

**Multipass VM Issues**
```bash
# Restart Multipass daemon
sudo launchctl unload /Library/LaunchDaemons/com.canonical.multipassd.plist
sudo launchctl load /Library/LaunchDaemons/com.canonical.multipassd.plist
```

**Docker Permission Issues**
```bash
# Add user to docker group
sudo usermod -aG docker $USER
# Log out and back in
```

**Juju Bootstrap Issues**
```bash
# Reset Juju
juju kill-controller <controller> --destroy-all-models
juju unregister <controller>
```

### Getting Help

1. Check the tool-specific README files
2. Review the logs: `just infrastructure-logs <environment>`
3. Run diagnostics: `just infrastructure-diagnose`
4. Check the [troubleshooting guide](docs/troubleshooting.md)

## 🏷️ Resource Tagging

All resources are tagged with:
- `Environment`: dev/staging/prod
- `Project`: Project name
- `Owner`: Team or individual responsible
- `CostCenter`: For billing allocation
- `Terraform`: true (if managed by Terraform)

## 💰 Cost Management

- **Resource Lifecycle**: Automatic cleanup of unused resources
- **Cost Estimation**: Pre-deployment cost analysis
- **Budget Alerts**: Notifications when spending thresholds are reached
- **Optimization**: Regular reviews and rightsizing recommendations

## 🔒 Security

- **Secrets Management**: Using external secret stores (Vault, cloud KMS)
- **Network Security**: VPCs, security groups, and network policies
- **Compliance**: Automated policy enforcement with OPA
- **Scanning**: Regular vulnerability and compliance scans

## 📊 Monitoring

The infrastructure includes comprehensive monitoring:
- **Metrics**: Prometheus and Grafana
- **Logs**: Centralized logging with ELK stack
- **Tracing**: Distributed tracing for microservices
- **Alerting**: PagerDuty/Slack integration for critical issues

## 🧪 Testing

- **Infrastructure Tests**: Terratest for Terraform validation
- **Integration Tests**: End-to-end deployment testing
- **Security Tests**: Automated security scanning
- **Performance Tests**: Load testing and benchmarking

## 📚 Additional Resources

- [Architecture Decision Records](docs/adr/)
- [Runbooks](docs/runbooks/)
- [Security Policies](security/policies/)
- [Cost Optimization Guide](docs/cost-optimization.md)
- [Disaster Recovery Plan](docs/disaster-recovery.md)
