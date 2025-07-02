#!/usr/bin/env python3
"""
Cloud Infrastructure Automation Script

This script provides automation for cloud infrastructure management across
multiple providers (OCI, AWS, local). It handles provisioning, configuration,
and lifecycle management of cloud resources.
"""

import os
import sys
import json
import yaml
import subprocess
import argparse
import logging
from pathlib import Path
from typing import Dict, List, Optional
from dataclasses import dataclass

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


@dataclass
class CloudConfig:
    """Configuration for cloud resources."""
    provider: str
    region: str
    environment: str
    project_name: str
    resource_tags: Dict[str, str]


class CloudAutomation:
    """Main class for cloud automation tasks."""
    
    def __init__(self, config_path: str = "infrastructure/config"):
        self.config_path = Path(config_path)
        self.terraform_path = Path("infrastructure/terraform")
        self.current_env = None
        
    def load_config(self, environment: str) -> CloudConfig:
        """Load configuration for specified environment."""
        config_file = self.config_path / "environments" / f"{environment}.yaml"
        
        if not config_file.exists():
            raise FileNotFoundError(f"Configuration file not found: {config_file}")
            
        with open(config_file, 'r') as f:
            config_data = yaml.safe_load(f)
            
        return CloudConfig(
            provider=config_data.get('cloud', {}).get('provider', 'local'),
            region=config_data.get('cloud', {}).get('region', 'local'),
            environment=environment,
            project_name=config_data.get('project', {}).get('name', 'template-analysis'),
            resource_tags=config_data.get('tags', {})
        )
    
    def validate_prerequisites(self, provider: str) -> bool:
        """Validate that required tools are installed."""
        required_tools = ['terraform']
        
        if provider == 'oci':
            required_tools.extend(['oci'])
        elif provider == 'aws':
            required_tools.extend(['aws'])
        elif provider == 'local':
            required_tools.extend(['multipass', 'docker'])
            
        missing_tools = []
        for tool in required_tools:
            try:
                subprocess.run([tool, '--version'], 
                             capture_output=True, check=True)
            except (subprocess.CalledProcessError, FileNotFoundError):
                missing_tools.append(tool)
                
        if missing_tools:
            logger.error(f"Missing required tools: {', '.join(missing_tools)}")
            return False
            
        return True
    
    def run_terraform(self, action: str, tf_dir: str, 
                     vars_file: Optional[str] = None) -> bool:
        """Run Terraform commands."""
        tf_path = self.terraform_path / tf_dir
        
        if not tf_path.exists():
            logger.error(f"Terraform directory not found: {tf_path}")
            return False
            
        logger.info(f"Running terraform {action} in {tf_path}")
        
        # Change to terraform directory
        original_cwd = os.getcwd()
        os.chdir(tf_path)
        
        try:
            # Initialize terraform if needed
            if action in ['plan', 'apply', 'destroy']:
                init_result = subprocess.run(
                    ['terraform', 'init'], 
                    capture_output=True, text=True
                )
                if init_result.returncode != 0:
                    logger.error(f"Terraform init failed: {init_result.stderr}")
                    return False
            
            # Build terraform command
            cmd = ['terraform', action]
            
            if vars_file:
                cmd.extend(['-var-file', vars_file])
                
            if action == 'apply':
                cmd.append('-auto-approve')
            elif action == 'destroy':
                cmd.append('-auto-approve')
                
            # Run terraform command
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                logger.info(f"Terraform {action} completed successfully")
                if result.stdout:
                    print(result.stdout)
                return True
            else:
                logger.error(f"Terraform {action} failed: {result.stderr}")
                return False
                
        finally:
            os.chdir(original_cwd)
    
    def provision_infrastructure(self, environment: str) -> bool:
        """Provision infrastructure for the specified environment."""
        config = self.load_config(environment)
        
        if not self.validate_prerequisites(config.provider):
            return False
            
        # Determine terraform directory based on provider
        if config.provider == 'oci':
            tf_dir = 'oci-vm'
        elif config.provider == 'aws':
            tf_dir = 'aws-ec2'  # Assuming this will be created
        else:
            tf_dir = 'local-multipass-vm'
            
        logger.info(f"Provisioning {config.provider} infrastructure for {environment}")
        
        # Create terraform variables file
        tf_vars = self._generate_terraform_vars(config)
        vars_file = f"{environment}.tfvars"
        
        with open(self.terraform_path / tf_dir / vars_file, 'w') as f:
            for key, value in tf_vars.items():
                f.write(f'{key} = "{value}"\n')
                
        # Run terraform
        return self.run_terraform('apply', tf_dir, vars_file)
    
    def destroy_infrastructure(self, environment: str) -> bool:
        """Destroy infrastructure for the specified environment."""
        config = self.load_config(environment)
        
        # Determine terraform directory
        if config.provider == 'oci':
            tf_dir = 'oci-vm'
        elif config.provider == 'aws':
            tf_dir = 'aws-ec2'
        else:
            tf_dir = 'local-multipass-vm'
            
        logger.info(f"Destroying {config.provider} infrastructure for {environment}")
        
        vars_file = f"{environment}.tfvars"
        return self.run_terraform('destroy', tf_dir, vars_file)
    
    def get_infrastructure_status(self, environment: str) -> Dict:
        """Get status of infrastructure resources."""
        config = self.load_config(environment)
        
        if config.provider == 'oci':
            tf_dir = 'oci-vm'
        elif config.provider == 'aws':
            tf_dir = 'aws-ec2'
        else:
            tf_dir = 'local-multipass-vm'
            
        tf_path = self.terraform_path / tf_dir
        
        if not (tf_path / 'terraform.tfstate').exists():
            return {'status': 'not_provisioned', 'resources': []}
            
        # Get terraform state
        original_cwd = os.getcwd()
        os.chdir(tf_path)
        
        try:
            result = subprocess.run(
                ['terraform', 'show', '-json'],
                capture_output=True, text=True
            )
            
            if result.returncode == 0:
                state_data = json.loads(result.stdout)
                return {
                    'status': 'provisioned',
                    'resources': self._extract_resource_info(state_data)
                }
            else:
                return {'status': 'error', 'error': result.stderr}
                
        finally:
            os.chdir(original_cwd)
    
    def _generate_terraform_vars(self, config: CloudConfig) -> Dict[str, str]:
        """Generate Terraform variables from configuration."""
        vars_dict = {
            'environment': config.environment,
            'project_name': config.project_name,
        }
        
        if config.provider == 'oci':
            # Add OCI-specific variables from environment
            oci_vars = [
                'tenancy_ocid', 'user_ocid', 'fingerprint',
                'private_key_path', 'region', 'compartment_ocid'
            ]
            for var in oci_vars:
                env_var = f'OCI_{var.upper()}'
                if env_var in os.environ:
                    vars_dict[var] = os.environ[env_var]
                    
        return vars_dict
    
    def _extract_resource_info(self, state_data: Dict) -> List[Dict]:
        """Extract useful resource information from Terraform state."""
        resources = []
        
        if 'values' in state_data and 'root_module' in state_data['values']:
            for resource in state_data['values']['root_module'].get('resources', []):
                resources.append({
                    'type': resource.get('type'),
                    'name': resource.get('name'),
                    'address': resource.get('address'),
                    'values': resource.get('values', {})
                })
                
        return resources


def main():
    """Main CLI entry point."""
    parser = argparse.ArgumentParser(
        description="Cloud Infrastructure Automation"
    )
    parser.add_argument(
        'action',
        choices=['provision', 'destroy', 'status', 'validate'],
        help='Action to perform'
    )
    parser.add_argument(
        'environment',
        help='Environment name (local, staging, production)'
    )
    parser.add_argument(
        '--config-path',
        default='infrastructure/config',
        help='Path to configuration files'
    )
    
    args = parser.parse_args()
    
    automation = CloudAutomation(args.config_path)
    
    try:
        if args.action == 'provision':
            success = automation.provision_infrastructure(args.environment)
            sys.exit(0 if success else 1)
            
        elif args.action == 'destroy':
            success = automation.destroy_infrastructure(args.environment)
            sys.exit(0 if success else 1)
            
        elif args.action == 'status':
            status = automation.get_infrastructure_status(args.environment)
            print(json.dumps(status, indent=2))
            
        elif args.action == 'validate':
            config = automation.load_config(args.environment)
            valid = automation.validate_prerequisites(config.provider)
            logger.info(f"Validation {'passed' if valid else 'failed'}")
            sys.exit(0 if valid else 1)
            
    except Exception as e:
        logger.error(f"Error: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()
