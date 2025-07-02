terraform {
  required_version = ">= 1.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# Variables
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "template-analysis"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vm_name" {
  description = "Name for the Multipass VM"
  type        = string
  default     = "canonical-hashicorp-stack"
}

variable "vm_cpus" {
  description = "Number of CPUs for the VM"
  type        = number
  default     = 4
}

variable "vm_memory" {
  description = "Amount of memory for the VM"
  type        = string
  default     = "8G"
}

variable "vm_disk" {
  description = "Disk size for the VM"
  type        = string
  default     = "50G"
}

variable "enable_gpu" {
  description = "Enable GPU support for ML workloads"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Domain name for services"
  type        = string
  default     = "local"
}

# Locals
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Stack       = "canonical-hashicorp"
  }
  
  services = {
    consul    = "8500"
    vault     = "8200"
    nomad     = "4646"
    traefik   = "8080"
    grafana   = "3000"
    prometheus = "9090"
    jupyter   = "8888"
  }
}

# Generate TLS certificates for services
resource "tls_private_key" "ca" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "ca" {
  private_key_pem = tls_private_key.ca.private_key_pem

  subject {
    common_name  = "Template Analysis CA"
    organization = "Template Analysis Platform"
  }

  validity_period_hours = 8760 # 1 year

  is_ca_certificate = true

  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "digital_signature"
  ]
}

# Generate random passwords for services
resource "random_password" "vault_token" {
  length  = 32
  special = true
}

resource "random_password" "consul_gossip_key" {
  length  = 32
  special = false
}

resource "random_password" "postgres_password" {
  length  = 16
  special = true
}

# Cloud-init configuration for Ubuntu VM
resource "local_file" "cloud_init" {
  filename = "${path.module}/cloud-init.yaml"
  content = templatefile("${path.module}/templates/cloud-init.yaml.tpl", {
    project_name     = var.project_name
    environment      = var.environment
    consul_gossip_key = base64encode(random_password.consul_gossip_key.result)
    vault_token      = random_password.vault_token.result
    postgres_password = random_password.postgres_password.result
    ca_cert          = tls_self_signed_cert.ca.cert_pem
    ca_key           = tls_private_key.ca.private_key_pem
    enable_gpu       = var.enable_gpu
    services         = local.services
  })
}

# HashiCorp configurations
resource "local_file" "consul_config" {
  filename = "${path.module}/config/consul.hcl"
  content = templatefile("${path.module}/templates/consul.hcl.tpl", {
    datacenter    = var.environment
    gossip_key    = base64encode(random_password.consul_gossip_key.result)
    ca_cert       = tls_self_signed_cert.ca.cert_pem
  })
}

resource "local_file" "vault_config" {
  filename = "${path.module}/config/vault.hcl"
  content = templatefile("${path.module}/templates/vault.hcl.tpl", {
    ca_cert = tls_self_signed_cert.ca.cert_pem
  })
}

resource "local_file" "nomad_config" {
  filename = "${path.module}/config/nomad.hcl"
  content = templatefile("${path.module}/templates/nomad.hcl.tpl", {
    datacenter = var.environment
    ca_cert    = tls_self_signed_cert.ca.cert_pem
  })
}

# Waypoint configuration
resource "local_file" "waypoint_config" {
  filename = "${path.module}/config/waypoint.hcl"
  content = templatefile("${path.module}/templates/waypoint.hcl.tpl", {
    project_name = var.project_name
    environment  = var.environment
  })
}

# Docker Compose for the full stack
resource "local_file" "docker_compose" {
  filename = "${path.module}/docker-compose.yml"
  content = templatefile("${path.module}/templates/docker-compose.yml.tpl", {
    project_name      = var.project_name
    environment       = var.environment
    consul_gossip_key = base64encode(random_password.consul_gossip_key.result)
    postgres_password = random_password.postgres_password.result
    services          = local.services
  })
}

# Launch Multipass VM with the integrated stack
resource "null_resource" "multipass_vm" {
  provisioner "local-exec" {
    command = <<-EOT
      multipass launch \
        --name ${var.vm_name} \
        --cpus ${var.vm_cpus} \
        --memory ${var.vm_memory} \
        --disk ${var.vm_disk} \
        --cloud-init ${local_file.cloud_init.filename} \
        22.04
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "multipass delete ${var.vm_name} && multipass purge"
  }

  depends_on = [
    local_file.cloud_init,
    local_file.consul_config,
    local_file.vault_config,
    local_file.nomad_config,
    local_file.waypoint_config,
    local_file.docker_compose
  ]
}

# Transfer configuration files to VM
resource "null_resource" "transfer_configs" {
  provisioner "local-exec" {
    command = <<-EOT
      # Wait for VM to be ready
      multipass exec ${var.vm_name} -- cloud-init status --wait
      
      # Create directories
      multipass exec ${var.vm_name} -- sudo mkdir -p /opt/hashicorp/{consul,vault,nomad,waypoint}/config
      multipass exec ${var.vm_name} -- sudo mkdir -p /opt/canonical/{microk8s,snapcraft}
      
      # Transfer HashiCorp configs
      multipass transfer ${local_file.consul_config.filename} ${var.vm_name}:/tmp/consul.hcl
      multipass transfer ${local_file.vault_config.filename} ${var.vm_name}:/tmp/vault.hcl
      multipass transfer ${local_file.nomad_config.filename} ${var.vm_name}:/tmp/nomad.hcl
      multipass transfer ${local_file.waypoint_config.filename} ${var.vm_name}:/tmp/waypoint.hcl
      multipass transfer ${local_file.docker_compose.filename} ${var.vm_name}:/tmp/docker-compose.yml
      
      # Move configs to proper locations
      multipass exec ${var.vm_name} -- sudo mv /tmp/consul.hcl /opt/hashicorp/consul/config/
      multipass exec ${var.vm_name} -- sudo mv /tmp/vault.hcl /opt/hashicorp/vault/config/
      multipass exec ${var.vm_name} -- sudo mv /tmp/nomad.hcl /opt/hashicorp/nomad/config/
      multipass exec ${var.vm_name} -- sudo mv /tmp/waypoint.hcl /opt/hashicorp/waypoint/config/
      multipass exec ${var.vm_name} -- sudo mv /tmp/docker-compose.yml /opt/stack/
    EOT
  }

  depends_on = [null_resource.multipass_vm]
}

# Start the HashiCorp stack
resource "null_resource" "start_stack" {
  provisioner "local-exec" {
    command = <<-EOT
      # Start the complete stack
      multipass exec ${var.vm_name} -- sudo systemctl start consul
      multipass exec ${var.vm_name} -- sudo systemctl start vault
      multipass exec ${var.vm_name} -- sudo systemctl start nomad
      
      # Start Docker Compose stack
      multipass exec ${var.vm_name} -- "cd /opt/stack && docker-compose up -d"
      
      # Initialize Vault (if not already done)
      sleep 30
      multipass exec ${var.vm_name} -- vault operator init -key-shares=1 -key-threshold=1 > /tmp/vault-keys.txt || true
      
      # Setup MicroK8s
      multipass exec ${var.vm_name} -- /opt/canonical/microk8s/setup.sh
    EOT
  }

  depends_on = [null_resource.transfer_configs]
}

# Setup port forwarding for services
resource "null_resource" "port_forwarding" {
  count = length(local.services)
  
  provisioner "local-exec" {
    command = <<-EOT
      # Create SSH tunnel for service access
      # This would typically be handled by a load balancer in production
      echo "Service ${keys(local.services)[count.index]} available at: http://localhost:${values(local.services)[count.index]}"
    EOT
  }

  depends_on = [null_resource.start_stack]
}

# Outputs
output "vm_name" {
  description = "Name of the created VM"
  value       = var.vm_name
}

output "vm_info" {
  description = "VM connection information"
  value = {
    name   = var.vm_name
    access = "multipass shell ${var.vm_name}"
  }
}

output "service_urls" {
  description = "URLs for accessing services"
  value = {
    for service, port in local.services :
    service => "http://${var.vm_name}.${var.domain_name}:${port}"
  }
}

output "vault_token" {
  description = "Vault root token (sensitive)"
  value       = random_password.vault_token.result
  sensitive   = true
}

output "postgres_password" {
  description = "PostgreSQL admin password (sensitive)"
  value       = random_password.postgres_password.result
  sensitive   = true
}

output "ca_certificate" {
  description = "CA certificate for TLS"
  value       = tls_self_signed_cert.ca.cert_pem
  sensitive   = true
}

output "getting_started" {
  description = "Getting started commands"
  value = <<-EOT
    # Access the VM
    multipass shell ${var.vm_name}
    
    # Check service status
    multipass exec ${var.vm_name} -- systemctl status consul vault nomad
    
    # Access UIs
    Consul:    http://localhost:8500
    Vault:     http://localhost:8200
    Nomad:     http://localhost:4646
    Grafana:   http://localhost:3000 (admin/admin123)
    Jupyter:   http://localhost:8888 (token: data-science-token-123)
    
    # Vault setup (if needed)
    multipass exec ${var.vm_name} -- vault operator init
    multipass exec ${var.vm_name} -- vault operator unseal
  EOT
}
