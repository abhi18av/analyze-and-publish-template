# Virtualization Infrastructure

This directory contains configurations and tools for various virtualization technologies used in the project.

## 🐳 Docker

Docker is used for containerizing applications and creating portable, consistent environments.

### Features
- Lightweight containerization
- Multi-stage builds for optimized images
- Docker Compose for multi-container applications
- Integration with CI/CD pipelines

### Usage
```bash
# Build and run containers
docker-compose up -d

# View running containers
docker ps

# View logs
docker-compose logs -f
```

### Directory Structure
```
docker/
├── Dockerfile              # Main application container
├── docker-compose.yml      # Multi-service composition
├── .dockerignore           # Files to exclude from build context
└── images/                 # Custom image definitions
```

## 📦 LXD

LXD provides system containers that are more like VMs but with container efficiency.

### Features
- System containers with full OS environments
- Resource limits and quotas
- Networking and storage management
- Snapshot and backup capabilities

### Setup on macOS
```bash
# Install LXD via Multipass
bash lxd/macos-multipass-lxd.sh

# Initialize LXD
lxd init
```

### Common Commands
```bash
# Launch a container
lxc launch ubuntu:22.04 mycontainer

# List containers
lxc list

# Execute commands
lxc exec mycontainer -- bash

# File transfer
lxc file push localfile mycontainer/path/to/remote
```

## 🚀 Multipass

Multipass creates Ubuntu VMs with cloud-init support for rapid development.

### Features
- Quick Ubuntu VM provisioning
- Cloud-init integration
- Resource management
- Easy file sharing

### Usage
```bash
# Launch VM with cloud-init
multipass launch --name dev-vm --cloud-init cloud-init/data-science.yml

# Access VM
multipass shell dev-vm

# Mount directories
multipass mount . dev-vm:/home/ubuntu/project

# View VM info
multipass info dev-vm
```

### Cloud-Init Configuration
See `multipass/cloud-init/data-science.yml` for a pre-configured data science environment.

## 🐋 Podman

Podman is a daemonless container engine compatible with Docker.

### Features
- Rootless containers
- Docker compatibility
- Kubernetes YAML support
- Built-in security features

### Migration from Docker
```bash
# Use podman as drop-in replacement
alias docker=podman

# Run containers
podman run -d nginx

# Generate Kubernetes YAML
podman generate kube
```

## 🔗 Integration

### With Terraform
All virtualization platforms can be managed via Terraform:
- `terraform/local-multipass-vm/` - Multipass VM provisioning
- `terraform/localcloud/` - Docker container orchestration

### With Juju
Applications can be deployed on LXD containers:
```bash
juju bootstrap localhost lxd-controller
juju deploy myapp --to lxd
```

### With Monitoring
All platforms integrate with the monitoring stack:
- Container metrics via cAdvisor
- VM metrics via node-exporter
- Log aggregation via centralized logging

## 🛠️ Best Practices

### Resource Management
- Set appropriate CPU and memory limits
- Use resource quotas to prevent resource exhaustion
- Monitor resource usage regularly

### Security
- Use non-root users in containers
- Apply security profiles (AppArmor/SELinux)
- Regular security updates
- Network segmentation

### Performance
- Use appropriate storage drivers
- Optimize image layers
- Enable resource monitoring
- Regular cleanup of unused resources

## 📚 References

- [Ubuntu Chiseled Containers](https://ubuntu.com/containers/chiseled) - Minimal Ubuntu container images
- [Docker Best Practices](https://docs.docker.com/develop/best-practices/)
- [LXD Documentation](https://linuxcontainers.org/lxd/docs/master/)
- [Multipass Documentation](https://multipass.run/docs)
- [Podman Documentation](https://podman.io/getting-started/)

## 🚨 Troubleshooting

### Common Issues

**Docker daemon not running**
```bash
sudo systemctl start docker
# or on macOS
open -a Docker
```

**LXD permission issues**
```bash
sudo usermod -a -G lxd $USER
# Log out and back in
```

**Multipass VM won't start**
```bash
# Check hypervisor
multipass get local.driver

# Restart service (macOS)
sudo launchctl unload /Library/LaunchDaemons/com.canonical.multipassd.plist
sudo launchctl load /Library/LaunchDaemons/com.canonical.multipassd.plist
```

**Podman rootless issues**
```bash
# Configure user namespaces
echo "$USER:100000:65536" | sudo tee /etc/subuid
echo "$USER:100000:65536" | sudo tee /etc/subgid
podman system migrate
```
