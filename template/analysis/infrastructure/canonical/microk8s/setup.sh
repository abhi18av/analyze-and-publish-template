#!/bin/bash

# MicroK8s Setup Script
# Sets up MicroK8s with essential addons for data science workloads

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on supported platform
check_platform() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        log_error "MicroK8s is not supported on macOS. Consider using Multipass with MicroK8s VM."
        exit 1
    fi
}

# Install MicroK8s
install_microk8s() {
    log_info "Installing MicroK8s..."
    
    if command -v microk8s &> /dev/null; then
        log_warn "MicroK8s is already installed"
        return 0
    fi
    
    # Install via snap
    sudo snap install microk8s --classic
    
    # Add user to microk8s group
    sudo usermod -a -G microk8s $USER
    sudo chown -f -R $USER ~/.kube
    
    log_info "MicroK8s installed successfully"
    log_warn "Please log out and back in for group changes to take effect"
}

# Wait for MicroK8s to be ready
wait_for_ready() {
    log_info "Waiting for MicroK8s to be ready..."
    microk8s status --wait-ready
    log_info "MicroK8s is ready"
}

# Enable essential addons
enable_addons() {
    log_info "Enabling essential addons..."
    
    # Core addons
    microk8s enable dns
    microk8s enable dashboard
    microk8s enable storage
    microk8s enable ingress
    microk8s enable metallb:10.64.140.43-10.64.140.49
    
    # Data science specific addons
    microk8s enable registry:size=20Gi
    microk8s enable prometheus
    microk8s enable gpu  # For ML workloads (if GPU available)
    
    # Additional useful addons
    microk8s enable helm3
    microk8s enable cert-manager
    
    log_info "Addons enabled successfully"
}

# Configure kubectl alias
configure_kubectl() {
    log_info "Configuring kubectl..."
    
    # Create kubectl alias
    if ! grep -q "alias kubectl='microk8s kubectl'" ~/.bashrc; then
        echo "alias kubectl='microk8s kubectl'" >> ~/.bashrc
    fi
    
    if ! grep -q "alias kubectl='microk8s kubectl'" ~/.zshrc 2>/dev/null; then
        echo "alias kubectl='microk8s kubectl'" >> ~/.zshrc 2>/dev/null || true
    fi
    
    # Export kubeconfig
    microk8s config > ~/.kube/config
    
    log_info "kubectl configured"
}

# Install additional tools
install_tools() {
    log_info "Installing additional tools..."
    
    # Install k9s for cluster management
    if ! command -v k9s &> /dev/null; then
        curl -sS https://webinstall.dev/k9s | bash
    fi
    
    # Install kubectx/kubens
    if ! command -v kubectx &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y kubectx
    fi
    
    log_info "Additional tools installed"
}

# Create data science namespace
create_namespace() {
    log_info "Creating data science namespace..."
    
    microk8s kubectl create namespace template-analysis || log_warn "Namespace might already exist"
    microk8s kubectl label namespace template-analysis app.kubernetes.io/name=template-analysis
    
    log_info "Namespace created"
}

# Deploy dashboard token
setup_dashboard() {
    log_info "Setting up dashboard access..."
    
    cat <<EOF | microk8s kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kube-system
EOF
    
    log_info "Dashboard admin user created"
    log_info "To access dashboard:"
    log_info "1. Run: microk8s kubectl port-forward -n kube-system service/kubernetes-dashboard 10443:443"
    log_info "2. Visit: https://localhost:10443"
    log_info "3. Get token: microk8s kubectl -n kube-system create token admin-user"
}

# Deploy monitoring stack
deploy_monitoring() {
    log_info "Deploying monitoring stack..."
    
    # Apply monitoring manifests if they exist
    if [ -d "../../monitoring/kubernetes" ]; then
        microk8s kubectl apply -f ../../monitoring/kubernetes/
    fi
    
    log_info "Monitoring stack deployed"
}

# Display status
show_status() {
    log_info "MicroK8s Setup Complete!"
    echo
    echo "Cluster Status:"
    microk8s status
    echo
    echo "Nodes:"
    microk8s kubectl get nodes
    echo
    echo "Addons:"
    microk8s status --format yaml | grep -A 50 "addons:"
    echo
    echo "Useful Commands:"
    echo "  microk8s status                    # Check cluster status"
    echo "  microk8s kubectl get all --all-namespaces  # List all resources"
    echo "  microk8s dashboard-proxy           # Access dashboard"
    echo "  microk8s reset                     # Reset cluster"
}

# Main execution
main() {
    log_info "Starting MicroK8s setup..."
    
    check_platform
    install_microk8s
    wait_for_ready
    enable_addons
    configure_kubectl
    install_tools
    create_namespace
    setup_dashboard
    deploy_monitoring
    show_status
    
    log_info "Setup completed successfully!"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-install)
            SKIP_INSTALL=true
            shift
            ;;
        --minimal)
            MINIMAL_INSTALL=true
            shift
            ;;
        --help)
            echo "Usage: $0 [--skip-install] [--minimal] [--help]"
            echo "  --skip-install: Skip MicroK8s installation"
            echo "  --minimal: Install only core addons"
            echo "  --help: Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Run main function
main
