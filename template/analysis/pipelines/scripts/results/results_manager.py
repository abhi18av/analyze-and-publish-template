#!/usr/bin/env python3
"""
Results Management System for Bioinformatics Pipelines
Provides organized directory structure and metadata tracking for pipeline runs
"""

import json
import os
import sys
import subprocess
import argparse
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional


class ResultsManager:
    """Manages pipeline results directories and metadata"""
    
    def __init__(self, base_results_dir: str = "results"):
        self.base_results_dir = Path(base_results_dir)
        self.base_results_dir.mkdir(exist_ok=True)
    
    def create_results_directory(self, 
                               workflow_type: str = "analysis",
                               project_name: str = "pipeline") -> Path:
        """Create organized results directory with metadata"""
        
        now = datetime.now()
        run_date = now.strftime("%Y-%m-%d")
        run_time = now.strftime("%H%M%S")
        
        # Create results directory path
        results_dir = self.base_results_dir / run_date / workflow_type / run_time
        
        # Create subdirectories based on workflow type
        subdirs = self._get_subdirectories(workflow_type)
        for subdir in subdirs:
            (results_dir / subdir).mkdir(parents=True, exist_ok=True)
        
        # Create run metadata
        self._create_run_metadata(results_dir, workflow_type, project_name)
        
        # Update latest symlink
        self._update_latest_symlink(workflow_type, run_date, run_time)
        
        return results_dir
    
    def _get_subdirectories(self, workflow_type: str) -> List[str]:
        """Get subdirectory structure based on workflow type"""
        
        subdirs_map = {
            'hyperopt': [
                '01_data_preparation',
                '02_optimization/trials',
                '03_validation',
                '04_reports',
                'pipeline_info'
            ],
            'training': [
                '01_preprocessing',
                '02_model_training',
                '03_evaluation',
                '04_reports',
                'pipeline_info'
            ],
            'inference': [
                '01_input_processing',
                '02_predictions',
                '03_quality_control',
                '04_reports',
                'pipeline_info'
            ],
            'analysis': [
                '01_preprocessing',
                '02_analysis',
                '03_reports',
                'pipeline_info'
            ]
        }
        
        return subdirs_map.get(workflow_type, subdirs_map['analysis'])
    
    def _create_run_metadata(self, 
                           results_dir: Path,
                           workflow_type: str,
                           project_name: str) -> None:
        """Create run metadata JSON file"""
        
        now = datetime.now()
        run_date = now.strftime("%Y-%m-%d")
        run_time = now.strftime("%H%M%S")
        run_id = f"{workflow_type}_{run_date.replace('-', '')}_{run_time}"
        
        # Get git information if available
        git_commit = self._get_git_commit()
        git_branch = self._get_git_branch()
        
        # Get nextflow version if available
        nextflow_version = self._get_nextflow_version()
        
        run_info = {
            "run_id": run_id,
            "project_name": project_name,
            "workflow_type": workflow_type,
            "start_time": now.isoformat(),
            "run_date": run_date,
            "run_time": run_time,
            "status": "running",
            "created_by": os.getenv('USER', 'unknown'),
            "hostname": os.uname().nodename,
            "working_directory": str(Path.cwd()),
            "git_commit": git_commit,
            "git_branch": git_branch,
            "nextflow_version": nextflow_version,
            "parameters": {},
            "results_path": str(results_dir),
            "compute_environment": "local"
        }
        
        metadata_file = results_dir / "run_info.json"
        with open(metadata_file, 'w') as f:
            json.dump(run_info, f, indent=2)
        
        print(f"Created run metadata: {metadata_file}")
    
    def _get_git_commit(self) -> str:
        """Get current git commit hash"""
        try:
            result = subprocess.run(['git', 'rev-parse', 'HEAD'], 
                                 capture_output=True, text=True, check=True)
            return result.stdout.strip()
        except (subprocess.CalledProcessError, FileNotFoundError):
            return "unknown"
    
    def _get_git_branch(self) -> str:
        """Get current git branch"""
        try:
            result = subprocess.run(['git', 'branch', '--show-current'],
                                 capture_output=True, text=True, check=True)
            return result.stdout.strip()
        except (subprocess.CalledProcessError, FileNotFoundError):
            return "unknown"
    
    def _get_nextflow_version(self) -> str:
        """Get Nextflow version"""
        try:
            result = subprocess.run(['nextflow', '-version'],
                                 capture_output=True, text=True, check=True)
            # Parse first line to get version
            first_line = result.stdout.split('\n')[0]
            return first_line.strip()
        except (subprocess.CalledProcessError, FileNotFoundError):
            return "unknown"
    
    def _update_latest_symlink(self, 
                             workflow_type: str,
                             run_date: str,
                             run_time: str) -> None:
        """Update latest symlink to point to most recent run"""
        
        latest_dir = self.base_results_dir / "latest"
        latest_dir.mkdir(exist_ok=True)
        
        symlink_path = latest_dir / workflow_type
        target_path = Path("..") / run_date / workflow_type / run_time
        
        # Remove existing symlink if it exists
        if symlink_path.exists() or symlink_path.is_symlink():
            symlink_path.unlink()
        
        # Create new symlink
        try:
            symlink_path.symlink_to(target_path)
            print(f"Updated latest symlink: {symlink_path} -> {target_path}")
        except OSError as e:
            print(f"Warning: Could not create symlink: {e}")
    
    def update_run_status(self, results_dir: Path, status: str) -> None:
        """Update run status in metadata"""
        
        metadata_file = results_dir / "run_info.json"
        if not metadata_file.exists():
            print(f"Warning: Metadata file not found: {metadata_file}")
            return
        
        try:
            with open(metadata_file, 'r') as f:
                run_info = json.load(f)
            
            run_info['status'] = status
            run_info['end_time'] = datetime.now().isoformat()
            
            with open(metadata_file, 'w') as f:
                json.dump(run_info, f, indent=2)
            
            print(f"Updated run status to: {status}")
        except Exception as e:
            print(f"Warning: Could not update run status: {e}")
    
    def find_runs(self, 
                  workflow_type: Optional[str] = None,
                  status: Optional[str] = None,
                  days_back: int = 7) -> List[Dict]:
        """Find runs matching criteria"""
        
        runs = []
        
        # Search for run_info.json files
        for metadata_file in self.base_results_dir.rglob("run_info.json"):
            try:
                with open(metadata_file, 'r') as f:
                    run_info = json.load(f)
                
                # Filter by workflow type
                if workflow_type and run_info.get('workflow_type') != workflow_type:
                    continue
                
                # Filter by status
                if status and run_info.get('status') != status:
                    continue
                
                # Filter by date (simple check on file modification time)
                if (datetime.now() - datetime.fromtimestamp(metadata_file.stat().st_mtime)).days > days_back:
                    continue
                
                runs.append(run_info)
                
            except Exception as e:
                print(f"Warning: Could not read metadata from {metadata_file}: {e}")
        
        return runs
    
    def cleanup_old_runs(self, days_old: int = 30, dry_run: bool = True) -> None:
        """Clean up runs older than specified days"""
        
        print(f"Finding runs older than {days_old} days...")
        
        for date_dir in self.base_results_dir.glob("????-??-??"):
            try:
                dir_date = datetime.strptime(date_dir.name, "%Y-%m-%d")
                age_days = (datetime.now() - dir_date).days
                
                if age_days > days_old:
                    if dry_run:
                        print(f"Would remove: {date_dir}")
                    else:
                        print(f"Removing: {date_dir}")
                        subprocess.run(['rm', '-rf', str(date_dir)], check=True)
                        
            except ValueError:
                # Skip directories that don't match date format
                continue
            except Exception as e:
                print(f"Error processing {date_dir}: {e}")


def main():
    """Command line interface"""
    
    parser = argparse.ArgumentParser(description="Pipeline Results Management")
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # Create command
    create_parser = subparsers.add_parser('create', help='Create new results directory')
    create_parser.add_argument('--workflow-type', default='analysis',
                             choices=['hyperopt', 'training', 'inference', 'analysis'],
                             help='Type of workflow')
    create_parser.add_argument('--project-name', default='pipeline',
                             help='Name of the project')
    create_parser.add_argument('--base-dir', default='results',
                             help='Base results directory')
    
    # Update status command
    status_parser = subparsers.add_parser('update-status', help='Update run status')
    status_parser.add_argument('results_dir', help='Results directory path')
    status_parser.add_argument('status', choices=['running', 'completed', 'failed'],
                             help='New status')
    
    # Find command
    find_parser = subparsers.add_parser('find', help='Find runs')
    find_parser.add_argument('--workflow-type', help='Filter by workflow type')
    find_parser.add_argument('--status', help='Filter by status')
    find_parser.add_argument('--days', type=int, default=7, help='Days back to search')
    find_parser.add_argument('--base-dir', default='results', help='Base results directory')
    
    # Cleanup command
    cleanup_parser = subparsers.add_parser('cleanup', help='Cleanup old runs')
    cleanup_parser.add_argument('--days', type=int, default=30, help='Days old threshold')
    cleanup_parser.add_argument('--dry-run', action='store_true', help='Show what would be deleted')
    cleanup_parser.add_argument('--base-dir', default='results', help='Base results directory')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return
    
    if args.command == 'create':
        manager = ResultsManager(args.base_dir)
        results_dir = manager.create_results_directory(args.workflow_type, args.project_name)
        print(str(results_dir))
    
    elif args.command == 'update-status':
        manager = ResultsManager()
        manager.update_run_status(Path(args.results_dir), args.status)
    
    elif args.command == 'find':
        manager = ResultsManager(args.base_dir)
        runs = manager.find_runs(args.workflow_type, args.status, args.days)
        for run in runs:
            print(f"{run['run_id']}: {run['workflow_type']} ({run['status']}) - {run['results_path']}")
    
    elif args.command == 'cleanup':
        manager = ResultsManager(args.base_dir)
        manager.cleanup_old_runs(args.days, args.dry_run)


if __name__ == '__main__':
    main()
