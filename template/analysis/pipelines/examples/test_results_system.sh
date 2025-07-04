#!/bin/bash

# Example: Test the results management system
# This script demonstrates how to use the results management system

set -euo pipefail

echo "=== Testing Pipeline Results Management System ==="
echo

# Change to the pipelines directory
cd "$(dirname "$0")/.."

echo "1. Testing Python results manager..."
echo "Creating hyperopt results directory:"
HYPEROPT_DIR=$(python3 scripts/results/results_manager.py create --workflow-type hyperopt --project-name test_project)
echo "Created: $HYPEROPT_DIR"
echo

echo "Creating training results directory:"
TRAINING_DIR=$(python3 scripts/results/results_manager.py create --workflow-type training --project-name test_project)
echo "Created: $TRAINING_DIR"
echo

echo "Creating inference results directory:"
INFERENCE_DIR=$(python3 scripts/results/results_manager.py create --workflow-type inference --project-name test_project)
echo "Created: $INFERENCE_DIR"
echo

echo "2. Testing status updates..."
python3 scripts/results/results_manager.py update-status "$HYPEROPT_DIR" completed
python3 scripts/results/results_manager.py update-status "$TRAINING_DIR" running
python3 scripts/results/results_manager.py update-status "$INFERENCE_DIR" failed
echo "Status updated for all runs"
echo

echo "3. Finding runs..."
echo "All completed runs:"
python3 scripts/results/results_manager.py find --status completed
echo

echo "All hyperopt runs:"
python3 scripts/results/results_manager.py find --workflow-type hyperopt
echo

echo "4. Checking directory structure..."
echo "Results directory structure:"
if [ -d "results" ]; then
    tree results/ 2>/dev/null || find results/ -type d | sort
else
    echo "No results directory found"
fi
echo

echo "5. Checking latest symlinks..."
echo "Latest symlinks:"
if [ -d "results/latest" ]; then
    ls -la results/latest/
else
    echo "No latest directory found"
fi
echo

echo "6. Testing shell script..."
echo "Creating analysis results directory with shell script:"
ANALYSIS_DIR=$(./scripts/results/create_results_dir.sh create analysis test_shell_project)
echo "Created: $ANALYSIS_DIR"
echo

echo "7. Showing run metadata..."
echo "Sample run metadata:"
if [ -f "$HYPEROPT_DIR/run_info.json" ]; then
    cat "$HYPEROPT_DIR/run_info.json" | head -20
else
    echo "No metadata file found"
fi
echo

echo "=== Test completed successfully! ==="
echo
echo "To clean up test results, run:"
echo "  python3 scripts/results/results_manager.py cleanup --days 0 --dry-run"
echo "  python3 scripts/results/results_manager.py cleanup --days 0  # actual cleanup"
