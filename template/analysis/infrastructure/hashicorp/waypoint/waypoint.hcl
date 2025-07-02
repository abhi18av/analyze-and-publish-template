# Waypoint Configuration
# HashiCorp Waypoint for application deployment and lifecycle

project = "template-analysis"

# Labels to apply to all apps in this project
labels = {
  "project" = "template-analysis"
  "team"    = "platform"
}

# Variables that can be used across all apps
variable "registry" {
  default = "localhost:5000"
  type    = string
}

variable "environment" {
  default = "development"
  type    = string
}

# Application: Jupyter Data Science Environment
app "jupyter" {
  labels = {
    "service" = "jupyter-lab"
    "tier"    = "frontend"
  }

  build {
    use "docker" {
      dockerfile = "Dockerfile.jupyter"
    }
    
    registry {
      use "docker" {
        image = "${var.registry}/jupyter"
        tag   = gitrefpretty()
      }
    }
  }

  deploy {
    use "nomad" {
      datacenter = "dc1"
      
      jobspec {
        template_file = "nomad/jupyter.nomad.tpl"
      }
    }
  }

  release {
    use "consul" {
      service = "jupyter"
      
      health_check {
        http {
          url = "http://localhost:8888/api"
        }
      }
    }
  }
}

# Application: Data Processing Pipeline
app "data-pipeline" {
  labels = {
    "service" = "data-processing"
    "tier"    = "backend"
  }

  build {
    use "docker" {
      dockerfile = "Dockerfile"
    }
    
    registry {
      use "docker" {
        image = "${var.registry}/data-pipeline"
        tag   = gitrefpretty()
      }
    }
  }

  deploy {
    use "nomad" {
      datacenter = "dc1"
      
      jobspec {
        template_file = "nomad/data-pipeline.nomad.tpl"
      }
    }
  }
}

# Application: API Service
app "api" {
  labels = {
    "service" = "api"
    "tier"    = "backend"
  }

  build {
    use "docker" {
      dockerfile = "Dockerfile.api"
    }
    
    registry {
      use "docker" {
        image = "${var.registry}/api"
        tag   = gitrefpretty()
      }
    }
  }

  deploy {
    use "nomad" {
      datacenter = "dc1"
      region     = "global"
      
      jobspec {
        template_file = "nomad/api.nomad.tpl"
      }
    }
  }

  release {
    use "consul" {
      service = "api"
      
      health_check {
        http {
          url = "http://localhost:8080/health"
        }
      }
    }
  }
}

# Runner configuration for different environments
runner {
  profile "local" {
    plugin_type = "local"
  }
  
  plugin "nomad" {
    runner {
      enable_exec = true
    }
  }
}

# Configuration for different environments
config {
  env = {
    "ENVIRONMENT" = var.environment
    "PROJECT"     = "template-analysis"
  }
  
  # Vault integration for secrets
  config_source = {
    type = "vault"
    config = {
      addr = "http://localhost:8200"
      path = "secret/data/template-analysis"
    }
  }
}

# Hooks for deployment lifecycle
hook {
  when    = "before-deploy"
  command = ["/bin/sh", "-c", "echo 'Starting deployment...'"]
}

hook {
  when    = "after-deploy"
  command = ["/bin/sh", "-c", "echo 'Deployment completed!'"]
}
