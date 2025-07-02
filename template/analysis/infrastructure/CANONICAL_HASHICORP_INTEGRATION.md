# 🏗️ Canonical + HashiCorp Infrastructure Integration

This document describes the integrated infrastructure platform built on **Canonical** and **HashiCorp** open-source technologies for data science and application workloads.

## 🎯 Architecture Overview

Our infrastructure combines the best of both ecosystems:

### 🏗️ **Canonical Foundation**
- **Ubuntu 22.04 LTS**: Base operating system across all deployments
- **Multipass**: Lightweight VMs for development and testing
- **LXD**: System containers for efficient resource utilization  
- **MicroK8s**: Production-ready Kubernetes for container orchestration
- **Juju**: Application lifecycle management and charm deployment
- **Snapcraft**: Application packaging and distribution

### ⚡ **HashiCorp Platform**
- **Terraform**: Infrastructure as Code for all environments
- **Vault**: Centralized secrets management and encryption
- **Consul**: Service discovery and distributed configuration
- **Nomad**: Workload orchestration for containers and VMs
- **Waypoint**: Application deployment and release management
- **Packer**: Automated machine image building

## 🔄 Integration Benefits

### **Unified Infrastructure Management**
- Single Terraform codebase managing both stacks
- Consistent networking and security policies
- Shared secrets management via Vault
- Centralized monitoring and logging

### **Flexible Workload Placement**
- **Kubernetes** for cloud-native applications
- **Nomad** for mixed workloads (containers + VMs)
- **Juju** for traditional applications and services
- **LXD** for system-level isolation

### **Developer Experience**
- **Multipass** for rapid local development
- **Waypoint** for streamlined deployments
- **Consul Connect** for secure service mesh
- **Vault** for seamless secret injection

## 🚀 Quick Start

### Prerequisites

```bash
# Install core tools
brew install terraform vault consul nomad waypoint
brew install multipass juju microk8s
brew install --cask docker

# Install additional tools
brew install just packer helm kubectl
```

### Deploy Full Stack

```bash
# Initialize and deploy the integrated stack
just full-stack-deploy dev

# Access services
just full-stack-status

# Check individual components
just hashicorp-start
just microk8s-setup
```

## 📋 Service Architecture

### **Core Services**

| Service | Port | Purpose | Access |
|---------|------|---------|--------|
| Consul | 8500 | Service discovery & config | http://localhost:8500 |
| Vault | 8200 | Secrets management | http://localhost:8200 |
| Nomad | 4646 | Workload orchestration | http://localhost:4646 |
| Traefik | 8080 | Load balancer & proxy | http://localhost:8080 |
| Grafana | 3000 | Metrics visualization | http://localhost:3000 |
| Jupyter | 8888 | Data science environment | http://localhost:8888 |

### **Supporting Services**

| Service | Port | Purpose |
|---------|------|---------|
| PostgreSQL | 5432 | Primary database |
| Redis | 6379 | Caching & sessions |
| MinIO | 9000/9001 | S3-compatible storage |
| Prometheus | 9090 | Metrics collection |

## 🏗️ Infrastructure Layers

### **Layer 1: Foundation (Canonical)**
```bash
# Ubuntu VMs via Multipass
multipass launch --name data-platform --cpus 4 --memory 8G --disk 50G

# LXD system containers  
lxc launch ubuntu:22.04 app-container

# MicroK8s cluster
microk8s enable dns dashboard storage ingress registry
```

### **Layer 2: Platform (HashiCorp)**
```bash
# Infrastructure provisioning
terraform apply -var environment=production

# Secrets management
vault kv put secret/myapp database_url="postgres://..."

# Service discovery
consul services register myapp.json

# Workload deployment
nomad job run myapp.nomad
```

### **Layer 3: Applications (Integrated)**
```bash
# Traditional apps via Juju
juju deploy postgresql
juju deploy myapp --to lxd

# Cloud-native apps via MicroK8s
kubectl apply -f k8s-manifests/

# Mixed workloads via Nomad
nomad job run mixed-workload.nomad

# Streamlined deployment via Waypoint
waypoint deploy
```

## 🔧 Configuration Management

### **Environment Configuration**
```yaml
# config/environments/production.yaml
environment:
  name: "production"
  
canonical:
  ubuntu_version: "22.04"
  microk8s_version: "1.28"
  juju_channel: "stable"
  
hashicorp:
  consul_version: "1.16"
  vault_version: "1.14"
  nomad_version: "1.6"
  
integration:
  service_mesh: true
  secrets_injection: true
  monitoring: true
```

### **Service Registration**
```bash
# Automatic service registration in Consul
just consul-register myapp 8080

# Secret storage in Vault  
just vault-put secret/myapp api_key "super-secret-key"

# Workload deployment via Nomad
just nomad-run myapp.nomad
```

## 📊 Monitoring & Observability

### **Metrics Collection**
- **Prometheus** scrapes metrics from all services
- **Grafana** provides dashboards and alerting
- **Consul** enables service health monitoring
- **Nomad** provides workload telemetry

### **Log Aggregation**
- Centralized logging via **Loki** or **ELK stack**
- Application logs from **Nomad** allocations
- System logs from **Ubuntu** and **MicroK8s**
- Audit logs from **Vault** and **Consul**

### **Distributed Tracing**
- **Jaeger** for request tracing
- **Consul Connect** for service mesh observability
- Integration with application frameworks

## 🔒 Security Model

### **Identity & Access**
- **Vault** for identity-based access
- **Consul ACLs** for service authorization  
- **Ubuntu Pro** for extended security
- **MicroK8s RBAC** for Kubernetes access

### **Network Security**
- **Consul Connect** service mesh
- **Calico** network policies in MicroK8s
- **UFW** firewall on Ubuntu hosts
- **Traefik** TLS termination

### **Secrets Management**
- **Vault** centralized secret storage
- **Consul** encrypted key-value store
- **Kubernetes Secrets** for pod-level secrets
- **Juju** secret management for charms

## 🧪 Development Workflow

### **Local Development**
```bash
# Start development environment
just dev-setup

# Deploy application locally
waypoint deploy -workspace=dev

# Test with local services
curl http://localhost:8080/api/health
```

### **Testing Pipeline**
```bash
# Infrastructure tests
just test-infrastructure

# Security scanning
just security-scan

# Integration tests  
just pipeline-run integration
```

### **Production Deployment**
```bash
# Deploy to staging
just full-stack-deploy staging

# Promote to production
waypoint release -workspace=production
```

## 🛠️ Operational Procedures

### **Backup & Recovery**
- **Consul** snapshot backups
- **Vault** encrypted backups
- **PostgreSQL** point-in-time recovery
- **Kubernetes** etcd backups

### **Scaling Operations**
- **Nomad** horizontal scaling
- **MicroK8s** cluster expansion
- **Consul** cluster growth
- **Load balancer** auto-scaling

### **Incident Response**
- **Grafana** alerting integration
- **PagerDuty** incident escalation
- **Consul** health checking
- **Vault** audit logging

## 📚 Learning Resources

### **Canonical Technologies**
- [Ubuntu Server Guide](https://ubuntu.com/server/docs)
- [Multipass Documentation](https://multipass.run/docs)
- [MicroK8s Documentation](https://microk8s.io/docs)
- [Juju Documentation](https://juju.is/docs)
- [LXD Documentation](https://linuxcontainers.org/lxd/)

### **HashiCorp Technologies**
- [Terraform Documentation](https://terraform.io/docs)
- [Vault Documentation](https://vaultproject.io/docs)
- [Consul Documentation](https://consul.io/docs)
- [Nomad Documentation](https://nomadproject.io/docs)
- [Waypoint Documentation](https://waypointproject.io/docs)

### **Integration Guides**
- [Consul + Kubernetes](https://consul.io/docs/k8s)
- [Vault + Nomad](https://nomadproject.io/docs/integrations/vault)
- [Terraform + Juju](https://juju.is/docs/terraform)

## 🤝 Contributing

### **Infrastructure Changes**
1. Update Terraform configurations
2. Test with `terraform plan`
3. Apply via automation pipeline
4. Update documentation

### **Service Integration**
1. Register service in Consul
2. Configure Vault secrets
3. Create Nomad job specification
4. Deploy via Waypoint

### **Monitoring**
1. Add Prometheus metrics
2. Create Grafana dashboards  
3. Configure alerting rules
4. Test incident procedures

## 🆘 Troubleshooting

### **Common Issues**

**Vault Sealed**
```bash
# Check status
vault status

# Unseal vault
just vault-unseal <unseal-key>
```

**Consul Connection Issues**
```bash
# Check cluster members
just consul-members

# Restart consul
systemctl restart consul
```

**Nomad Job Failures**
```bash
# Check job status
just nomad-status <job-name>

# View job logs
nomad alloc logs <alloc-id>
```

**MicroK8s Issues**
```bash
# Check status
just microk8s-status

# Reset cluster
microk8s reset
```

### **Getting Help**
- Check service logs: `journalctl -u <service>`
- Review Terraform state: `terraform show`
- Consul debug: `consul members -detailed`
- Vault debug: `vault status -detailed`

---

🎉 **Ready to build the future of infrastructure!** 

This integrated platform provides enterprise-grade capabilities with open-source flexibility, enabling rapid development and reliable production deployments.
