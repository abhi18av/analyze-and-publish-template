# Vault Configuration
# HashiCorp Vault for secrets management and encryption

ui = true
disable_mlock = true

# Storage backend - using file for local development
# For production, consider using Consul, database, or cloud storage
storage "file" {
  path = "/vault/data"
}

# Listener configuration
listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1  # Disable for local development only
  
  # For production, enable TLS:
  # tls_cert_file = "/path/to/cert.pem"
  # tls_key_file  = "/path/to/key.pem"
}

# API address
api_addr = "http://127.0.0.1:8200"

# Cluster address
cluster_addr = "https://127.0.0.1:8201"

# Telemetry
telemetry {
  prometheus_retention_time = "30s"
  disable_hostname          = true
}

# Log level
log_level = "INFO"

# Default lease and max lease TTL
default_lease_ttl = "168h"
max_lease_ttl     = "720h"

# Plugin directory
plugin_directory = "/vault/plugins"
