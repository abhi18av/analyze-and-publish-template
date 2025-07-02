# Consul Configuration
# HashiCorp Consul for service discovery and configuration

# Data directory
data_dir = "/consul/data"

# Log level
log_level = "INFO"

# Node name
node_name = "consul-server"

# Datacenter
datacenter = "dc1"

# Server mode
server = true

# Bootstrap expect (number of servers in cluster)
bootstrap_expect = 1

# UI configuration
ui_config {
  enabled = true
}

# Client address
client_addr = "0.0.0.0"

# Bind address
bind_addr = "0.0.0.0"

# Connect (service mesh) configuration
connect {
  enabled = true
}

# Ports configuration
ports {
  grpc = 8502
  http = 8500
  https = 8501
  dns = 8600
}

# ACL configuration (for production)
acl = {
  enabled = false  # Enable for production
  default_policy = "allow"
  enable_token_persistence = true
}

# Performance tuning
performance {
  raft_multiplier = 1
}

# Logging
enable_syslog = false

# Telemetry
telemetry {
  prometheus_retention_time = "60s"
  disable_hostname = true
}

# Retry join for clustering (add other Consul servers)
# retry_join = ["10.0.1.10", "10.0.1.11"]

# Encrypt network traffic (generate with: consul keygen)
# encrypt = "your-encryption-key-here"
