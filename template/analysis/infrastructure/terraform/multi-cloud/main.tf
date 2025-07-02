terraform {
  required_version = ">= 1.0"
  
  required_providers {
    # Oracle Cloud Infrastructure (Primary)
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
    
    # Google Cloud Platform (Secondary)
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    
    # Amazon Web Services (Secondary)
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    
    # Vault for secrets management
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.0"
    }
    
    # Consul for service discovery
    consul = {
      source  = "hashicorp/consul"
      version = "~> 2.0"
    }
    
    # Third-party providers
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    
    # Utilities
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

# Variables for multi-cloud configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "template-analysis"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "primary_region" {
  description = "Primary region for Oracle Cloud"
  type        = string
  default     = "us-ashburn-1"
}

variable "enable_gcp" {
  description = "Enable Google Cloud resources"
  type        = bool
  default     = true
}

variable "enable_aws" {
  description = "Enable AWS resources"
  type        = bool
  default     = true
}

variable "enable_third_party" {
  description = "Enable third-party providers"
  type        = bool
  default     = true
}

variable "data_residency_regions" {
  description = "Allowed regions for data storage"
  type        = list(string)
  default     = ["us-ashburn-1", "us-phoenix-1", "us-central1", "us-east-1"]
}

# Local values
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Stack       = "multi-cloud-hybrid"
    CreatedAt   = timestamp()
  }
  
  # Resource distribution strategy
  resource_strategy = {
    # Primary workloads on Oracle Cloud
    primary = {
      provider = "oci"
      region   = var.primary_region
      workloads = [
        "database",
        "compute-primary",
        "storage-primary",
        "networking-core"
      ]
    }
    
    # Secondary workloads on GCP
    secondary_gcp = {
      provider = "gcp"
      region   = "us-central1"
      workloads = [
        "ai-ml-services",
        "analytics",
        "backup-storage"
      ]
    }
    
    # Secondary workloads on AWS
    secondary_aws = {
      provider = "aws"
      region   = "us-east-1"
      workloads = [
        "cdn",
        "edge-compute",
        "disaster-recovery"
      ]
    }
    
    # Third-party services
    third_party = {
      workloads = [
        "dns",
        "monitoring-external",
        "backup-external"
      ]
    }
  }
  
  # Network configuration
  network_config = {
    # Private network ranges for each cloud
    oci_cidr     = "10.0.0.0/16"
    gcp_cidr     = "10.1.0.0/16"
    aws_cidr     = "10.2.0.0/16"
    local_cidr   = "192.168.0.0/16"
    
    # VPN and interconnects
    enable_vpn   = true
    enable_peering = true
  }
}

# Random ID for unique resource naming
resource "random_id" "deployment" {
  byte_length = 4
}

# Generate TLS certificates for inter-cloud communication
resource "tls_private_key" "ca" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "ca" {
  private_key_pem = tls_private_key.ca.private_key_pem

  subject {
    common_name  = "${var.project_name} Multi-Cloud CA"
    organization = "Template Analysis Platform"
  }

  validity_period_hours = 8760 # 1 year
  is_ca_certificate     = true

  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "digital_signature"
  ]
}

# Oracle Cloud Infrastructure (Primary)
module "oci_primary" {
  source = "../oci-primary"
  
  project_name    = var.project_name
  environment     = var.environment
  region          = var.primary_region
  deployment_id   = random_id.deployment.hex
  
  # Network configuration
  vcn_cidr        = local.network_config.oci_cidr
  enable_peering  = local.network_config.enable_peering
  
  # Resource configuration
  workloads       = local.resource_strategy.primary.workloads
  
  # Security
  ca_cert         = tls_self_signed_cert.ca.cert_pem
  ca_key          = tls_private_key.ca.private_key_pem
  
  tags = local.common_tags
}

# Google Cloud Platform (Secondary)
module "gcp_secondary" {
  count  = var.enable_gcp ? 1 : 0
  source = "../gcp-secondary"
  
  project_name    = var.project_name
  environment     = var.environment
  region          = local.resource_strategy.secondary_gcp.region
  deployment_id   = random_id.deployment.hex
  
  # Network configuration
  vpc_cidr        = local.network_config.gcp_cidr
  
  # Resource configuration
  workloads       = local.resource_strategy.secondary_gcp.workloads
  
  # Integration with OCI
  oci_region      = var.primary_region
  oci_vpc_id      = module.oci_primary.vpc_id
  
  # Security
  ca_cert         = tls_self_signed_cert.ca.cert_pem
  
  tags = local.common_tags
}

# Amazon Web Services (Secondary)
module "aws_secondary" {
  count  = var.enable_aws ? 1 : 0
  source = "../aws-secondary"
  
  project_name    = var.project_name
  environment     = var.environment
  region          = local.resource_strategy.secondary_aws.region
  deployment_id   = random_id.deployment.hex
  
  # Network configuration
  vpc_cidr        = local.network_config.aws_cidr
  
  # Resource configuration
  workloads       = local.resource_strategy.secondary_aws.workloads
  
  # Integration with OCI
  oci_region      = var.primary_region
  oci_vpc_id      = module.oci_primary.vpc_id
  
  # Security
  ca_cert         = tls_self_signed_cert.ca.cert_pem
  
  tags = local.common_tags
}

# Third-party providers (Cloudflare, etc.)
module "third_party_providers" {
  count  = var.enable_third_party ? 1 : 0
  source = "../third-party-providers"
  
  project_name    = var.project_name
  environment     = var.environment
  deployment_id   = random_id.deployment.hex
  
  # Primary endpoints
  oci_load_balancer_ip = module.oci_primary.load_balancer_ip
  gcp_load_balancer_ip = var.enable_gcp ? module.gcp_secondary[0].load_balancer_ip : null
  aws_load_balancer_ip = var.enable_aws ? module.aws_secondary[0].load_balancer_ip : null
  
  # DNS configuration
  domain_name = "${var.project_name}-${var.environment}.example.com"
  
  tags = local.common_tags
}

# Multi-cloud networking
module "multi_cloud_networking" {
  source = "../modules/multi-cloud-networking"
  
  project_name  = var.project_name
  environment   = var.environment
  deployment_id = random_id.deployment.hex
  
  # Cloud configurations
  oci_config = {
    region = var.primary_region
    vpc_id = module.oci_primary.vpc_id
    cidr   = local.network_config.oci_cidr
  }
  
  gcp_config = var.enable_gcp ? {
    region = local.resource_strategy.secondary_gcp.region
    vpc_id = module.gcp_secondary[0].vpc_id
    cidr   = local.network_config.gcp_cidr
  } : null
  
  aws_config = var.enable_aws ? {
    region = local.resource_strategy.secondary_aws.region
    vpc_id = module.aws_secondary[0].vpc_id
    cidr   = local.network_config.aws_cidr
  } : null
  
  # Peering configuration
  enable_peering = local.network_config.enable_peering
  enable_vpn     = local.network_config.enable_vpn
  
  tags = local.common_tags
}

# Consul cluster for service discovery across clouds
resource "consul_config_entry" "service_mesh" {
  kind = "proxy-defaults"
  name = "global"

  config_json = jsonencode({
    protocol = "http"
    mesh_gateway = {
      mode = "local"
    }
    expose = {
      checks = true
    }
  })
}

# Vault configuration for multi-cloud secrets
resource "vault_mount" "multi_cloud" {
  path = "multi-cloud"
  type = "kv-v2"
  
  description = "Multi-cloud secrets and configuration"
}

# Store cloud credentials in Vault
resource "vault_kv_secret_v2" "cloud_credentials" {
  mount = vault_mount.multi_cloud.path
  name  = "cloud-credentials"
  
  data_json = jsonencode({
    oci = {
      tenancy_ocid     = var.oci_tenancy_ocid
      user_ocid        = var.oci_user_ocid
      region           = var.primary_region
    }
    gcp = var.enable_gcp ? {
      project_id = var.gcp_project_id
      region     = local.resource_strategy.secondary_gcp.region
    } : {}
    aws = var.enable_aws ? {
      region = local.resource_strategy.secondary_aws.region
    } : {}
  })
}

# Outputs
output "deployment_info" {
  description = "Multi-cloud deployment information"
  value = {
    deployment_id = random_id.deployment.hex
    environment   = var.environment
    
    primary_cloud = {
      provider = "oci"
      region   = var.primary_region
      resources = module.oci_primary.resource_summary
    }
    
    secondary_clouds = merge(
      var.enable_gcp ? {
        gcp = {
          provider = "gcp"
          region   = local.resource_strategy.secondary_gcp.region
          resources = module.gcp_secondary[0].resource_summary
        }
      } : {},
      
      var.enable_aws ? {
        aws = {
          provider = "aws"
          region   = local.resource_strategy.secondary_aws.region
          resources = module.aws_secondary[0].resource_summary
        }
      } : {}
    )
    
    third_party = var.enable_third_party ? {
      dns = module.third_party_providers[0].dns_info
      cdn = module.third_party_providers[0].cdn_info
    } : null
  }
  
  sensitive = false
}

output "service_endpoints" {
  description = "Service endpoints across all clouds"
  value = {
    primary = {
      consul    = "https://${module.oci_primary.consul_endpoint}"
      vault     = "https://${module.oci_primary.vault_endpoint}"
      nomad     = "https://${module.oci_primary.nomad_endpoint}"
      grafana   = "https://${module.oci_primary.grafana_endpoint}"
    }
    
    secondary = merge(
      var.enable_gcp ? {
        gcp_analytics = "https://${module.gcp_secondary[0].analytics_endpoint}"
        gcp_ml       = "https://${module.gcp_secondary[0].ml_endpoint}"
      } : {},
      
      var.enable_aws ? {
        aws_cdn      = "https://${module.aws_secondary[0].cdn_endpoint}"
        aws_backup   = "https://${module.aws_secondary[0].backup_endpoint}"
      } : {}
    )
    
    global = var.enable_third_party ? {
      domain = module.third_party_providers[0].domain_name
      cdn    = module.third_party_providers[0].cdn_url
    } : null
  }
}

output "network_configuration" {
  description = "Multi-cloud network configuration"
  value = {
    oci_cidr   = local.network_config.oci_cidr
    gcp_cidr   = var.enable_gcp ? local.network_config.gcp_cidr : null
    aws_cidr   = var.enable_aws ? local.network_config.aws_cidr : null
    local_cidr = local.network_config.local_cidr
    
    peering_enabled = local.network_config.enable_peering
    vpn_enabled     = local.network_config.enable_vpn
  }
}

output "management_commands" {
  description = "Commands for managing the multi-cloud deployment"
  value = <<-EOT
    # Multi-cloud status
    just multi-cloud-status
    
    # Deploy to specific cloud
    just deploy-oci ${var.environment}
    just deploy-gcp ${var.environment}
    just deploy-aws ${var.environment}
    
    # Cross-cloud operations
    just consul-federate
    just vault-replicate
    just setup-cross-cloud-monitoring
    
    # Disaster recovery
    just failover-to-secondary
    just restore-from-backup
  EOT
}
