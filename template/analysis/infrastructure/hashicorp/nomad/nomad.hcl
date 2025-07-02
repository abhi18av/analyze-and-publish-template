# Nomad Configuration
# HashiCorp Nomad for workload orchestration

# Data directory
data_dir = "/nomad/data"

# Log level
log_level = "INFO"

# Name
name = "nomad-server"

# Datacenter
datacenter = "dc1"

# Region
region = "global"

# Server configuration
server {
  enabled          = true
  bootstrap_expect = 1
  
  # Server join configuration for clustering
  # server_join {
  #   retry_join = ["10.0.1.10:4648", "10.0.1.11:4648"]
  # }
}

# Client configuration
client {
  enabled = true
  
  # Available drivers
  options {
    "driver.allowlist" = "docker,exec,raw_exec"
  }
  
  # Host volumes
  host_volume "data" {
    path      = "/nomad/data/volumes"
    read_only = false
  }
}

# UI configuration
ui {
  enabled = true
  
  # Consul UI integration
  consul {
    ui_url = "http://localhost:8500/ui"
  }
  
  # Vault UI integration
  vault {
    ui_url = "http://localhost:8200/ui"
  }
}

# Plugin configuration
plugin "docker" {
  config {
    enabled = true
    
    # Docker daemon configuration
    endpoint = "unix:///var/run/docker.sock"
    
    # Allow privileged containers (be careful in production)
    allow_privileged = false
    
    # Garbage collection
    gc {
      image       = true
      image_delay = "3m"
      container   = true
    }
    
    # Volume configuration
    volumes {
      enabled = true
    }
  }
}

# Consul integration
consul {
  address = "127.0.0.1:8500"
  
  # Auto advertise
  auto_advertise      = true
  server_auto_join    = true
  client_auto_join    = true
  
  # Service discovery
  client_service_name = "nomad-client"
  server_service_name = "nomad"
}

# Vault integration
vault {
  enabled = true
  address = "http://127.0.0.1:8200"
  
  # Task token TTL
  task_token_ttl = "1h"
  
  # Create from role
  create_from_role = "nomad-cluster"
}

# Telemetry
telemetry {
  collection_interval = "1s"
  disable_hostname    = true
  prometheus_metrics  = true
  publish_allocation_metrics = true
  publish_node_metrics = true
}

# ACL configuration (for production)
acl {
  enabled = false  # Enable for production
}

# TLS configuration (for production)
# tls {
#   http = true
#   rpc  = true
#   
#   ca_file   = "/path/to/ca.pem"
#   cert_file = "/path/to/cert.pem"
#   key_file  = "/path/to/key.pem"
# }

# Addresses and ports
addresses {
  http = "0.0.0.0"
  rpc  = "0.0.0.0"
  serf = "0.0.0.0"
}

ports {
  http = 4646
  rpc  = 4647
  serf = 4648
}
