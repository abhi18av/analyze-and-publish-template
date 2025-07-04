#!/bin/bash

# Results Directory Management Script
# Creates organized directory structure for pipeline results

set -euo pipefail

# Configuration
BASE_RESULTS_DIR="results"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Function to create results directory
create_results_directory() {
    local workflow_type="${1:-analysis}"
    local run_date=$(date +"%Y-%m-%d")
    local run_time=$(date +"%H%M%S")
    local project_name="${2:-pipeline}"
    
    # Create results directory path
    local results_dir="${PROJECT_ROOT}/${BASE_RESULTS_DIR}/${run_date}/${workflow_type}/${run_time}"
    
    echo "Creating results directory: ${results_dir}" >&2
    
    # Create directory structure based on workflow type
    case "${workflow_type}" in
        "hyperopt")
            mkdir -p "${results_dir}"/{01_data_preparation,02_optimization/trials,03_validation,04_reports,pipeline_info}
            ;;
        "training")
            mkdir -p "${results_dir}"/{01_preprocessing,02_model_training,03_evaluation,04_reports,pipeline_info}
            ;;
        "inference")
            mkdir -p "${results_dir}"/{01_input_processing,02_predictions,03_quality_control,04_reports,pipeline_info}
            ;;
        *)
            mkdir -p "${results_dir}"/{01_preprocessing,02_analysis,03_reports,pipeline_info}
            ;;
    esac
    
    # Create run info metadata
    create_run_metadata "${results_dir}" "${workflow_type}" "${project_name}"
    
    # Update latest symlink
    update_latest_symlink "${workflow_type}" "${run_date}" "${run_time}"
    
    # Return the results directory path
    echo "${results_dir}"
}

# Function to create run metadata
create_run_metadata() {
    local results_dir="$1"
    local workflow_type="$2"
    local project_name="$3"
    local run_date=$(date +"%Y-%m-%d")
    local run_time=$(date +"%H%M%S")
    
    # Get git information if available
    local git_commit="unknown"
    local git_branch="unknown"
    if git rev-parse --git-dir > /dev/null 2>&1; then
        git_commit=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
        git_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
    fi
    
    # Create run info JSON
    cat > "${results_dir}/run_info.json" << EOF
{
    "run_id": "${workflow_type}_${run_date//-/}_${run_time}",
    "project_name": "${project_name}",
    "workflow_type": "${workflow_type}",
    "start_time": "$(date -Iseconds)",
    "run_date": "${run_date}",
    "run_time": "${run_time}",
    "status": "running",
    "created_by": "$(whoami)",
    "hostname": "$(hostname)",
    "working_directory": "$(pwd)",
    "git_commit": "${git_commit}",
    "git_branch": "${git_branch}",
    "nextflow_version": "$(nextflow -version 2>/dev/null | head -1 || echo 'unknown')",
    "parameters": {},
    "results_path": "${results_dir}",
    "compute_environment": "local"
}
EOF

    echo "Created run metadata: ${results_dir}/run_info.json" >&2
}

# Function to update latest symlinks
update_latest_symlink() {
    local workflow_type="$1"
    local run_date="$2"
    local run_time="$3"
    
    local latest_dir="${PROJECT_ROOT}/${BASE_RESULTS_DIR}/latest"
    mkdir -p "${latest_dir}"
    
    # Create symlink to latest run
    local target="../${run_date}/${workflow_type}/${run_time}"
    ln -sfn "${target}" "${latest_dir}/${workflow_type}"
    
    echo "Updated latest symlink: ${latest_dir}/${workflow_type} -> ${target}" >&2
}

# Function to update run status
update_run_status() {
    local results_dir="$1"
    local status="$2"
    local metadata_file="${results_dir}/run_info.json"
    
    if [[ -f "${metadata_file}" ]]; then
        # Use jq if available, otherwise use sed
        if command -v jq > /dev/null 2>&1; then
            local temp_file=$(mktemp)
            jq --arg status "${status}" --arg end_time "$(date -Iseconds)" \
               '.status = $status | .end_time = $end_time' \
               "${metadata_file}" > "${temp_file}"
            mv "${temp_file}" "${metadata_file}"
        else
            # Fallback to sed (less robust but works without jq)
            sed -i.bak "s/\"status\": \"running\"/\"status\": \"${status}\"/" "${metadata_file}"
            rm -f "${metadata_file}.bak"
        fi
        echo "Updated run status to: ${status}" >&2
    fi
}

# Function to find runs
find_runs() {
    local workflow_type="${1:-}"
    local status="${2:-}"
    local days_back="${3:-7}"
    
    local search_dir="${PROJECT_ROOT}/${BASE_RESULTS_DIR}"
    
    find "${search_dir}" -name "run_info.json" -type f -mtime -"${days_back}" | while read -r metadata_file; do
        if [[ -f "${metadata_file}" ]]; then
            # Extract information using grep (works without jq)
            local run_workflow=$(grep -o '"workflow_type": "[^"]*"' "${metadata_file}" | cut -d'"' -f4)
            local run_status=$(grep -o '"status": "[^"]*"' "${metadata_file}" | cut -d'"' -f4)
            local run_id=$(grep -o '"run_id": "[^"]*"' "${metadata_file}" | cut -d'"' -f4)
            
            # Filter by workflow type if specified
            if [[ -n "${workflow_type}" && "${run_workflow}" != "${workflow_type}" ]]; then
                continue
            fi
            
            # Filter by status if specified
            if [[ -n "${status}" && "${run_status}" != "${status}" ]]; then
                continue
            fi
            
            echo "${run_id}: ${run_workflow} (${run_status}) - ${metadata_file%/run_info.json}"
        fi
    done
}

# Function to cleanup old runs
cleanup_old_runs() {
    local days_old="${1:-30}"
    local dry_run="${2:-false}"
    
    local search_dir="${PROJECT_ROOT}/${BASE_RESULTS_DIR}"
    
    echo "Finding runs older than ${days_old} days..." >&2
    
    find "${search_dir}" -type d -name "[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]" -mtime +"${days_old}" | while read -r date_dir; do
        if [[ "${dry_run}" == "true" ]]; then
            echo "Would remove: ${date_dir}"
        else
            echo "Removing: ${date_dir}" >&2
            rm -rf "${date_dir}"
        fi
    done
}

# Main execution
main() {
    case "${1:-help}" in
        "create")
            create_results_directory "${2:-analysis}" "${3:-pipeline}"
            ;;
        "update-status")
            update_run_status "$2" "$3"
            ;;
        "find")
            find_runs "${2:-}" "${3:-}" "${4:-7}"
            ;;
        "cleanup")
            cleanup_old_runs "${2:-30}" "${3:-false}"
            ;;
        "help"|*)
            cat << 'EOF'
Usage: create_results_dir.sh <command> [options]

Commands:
    create [workflow_type] [project_name]  - Create new results directory
    update-status <results_dir> <status>   - Update run status
    find [workflow_type] [status] [days]   - Find runs (last 7 days by default)
    cleanup [days] [dry_run]               - Cleanup runs older than days
    help                                   - Show this help

Workflow types: hyperopt, training, inference, analysis (default)
Status values: running, completed, failed

Examples:
    ./create_results_dir.sh create hyperopt my_project
    ./create_results_dir.sh update-status results/2025-07-04/hyperopt/143025 completed
    ./create_results_dir.sh find hyperopt completed
    ./create_results_dir.sh cleanup 30 true  # dry run
EOF
            ;;
    esac
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
