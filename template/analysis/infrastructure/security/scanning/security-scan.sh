#!/bin/bash

# Security Scanning Script
# This script runs various security scanning tools against the codebase and infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCAN_DIR="${1:-$(pwd)}"
OUTPUT_DIR="infrastructure/security/scanning/reports"
DATE=$(date +%Y%m%d_%H%M%S)

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo -e "${GREEN}Starting security scan at $(date)${NC}"
echo -e "${GREEN}Scanning directory: $SCAN_DIR${NC}"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install tools if missing
install_security_tools() {
    echo -e "${YELLOW}Installing security tools...${NC}"
    
    # Install Python security tools
    if command_exists pip; then
        pip install bandit safety semgrep
    fi
    
    # Install trivy for container scanning
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command_exists brew; then
            brew install trivy
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Install trivy on Linux
        curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
    fi
    
    # Install tfsec for Terraform scanning
    if command_exists go; then
        go install github.com/aquasecurity/tfsec/cmd/tfsec@latest
    fi
}

# Python security scanning with Bandit
run_bandit_scan() {
    if command_exists bandit; then
        echo -e "${GREEN}Running Bandit security scan...${NC}"
        bandit -r "$SCAN_DIR" -f json -o "$OUTPUT_DIR/bandit_report_$DATE.json" || true
        bandit -r "$SCAN_DIR" -f txt -o "$OUTPUT_DIR/bandit_report_$DATE.txt" || true
        echo -e "${GREEN}✓ Bandit scan completed${NC}"
    else
        echo -e "${YELLOW}⚠ Bandit not found, skipping Python security scan${NC}"
    fi
}

# Python dependency vulnerability scanning with Safety
run_safety_scan() {
    if command_exists safety; then
        echo -e "${GREEN}Running Safety dependency scan...${NC}"
        safety check --json --output "$OUTPUT_DIR/safety_report_$DATE.json" || true
        safety check --output "$OUTPUT_DIR/safety_report_$DATE.txt" || true
        echo -e "${GREEN}✓ Safety scan completed${NC}"
    else
        echo -e "${YELLOW}⚠ Safety not found, skipping dependency vulnerability scan${NC}"
    fi
}

# Semgrep static analysis
run_semgrep_scan() {
    if command_exists semgrep; then
        echo -e "${GREEN}Running Semgrep static analysis...${NC}"
        semgrep --config=auto "$SCAN_DIR" --json --output="$OUTPUT_DIR/semgrep_report_$DATE.json" || true
        semgrep --config=auto "$SCAN_DIR" --output="$OUTPUT_DIR/semgrep_report_$DATE.txt" || true
        echo -e "${GREEN}✓ Semgrep scan completed${NC}"
    else
        echo -e "${YELLOW}⚠ Semgrep not found, skipping static analysis${NC}"
    fi
}

# Container image scanning with Trivy
run_trivy_scan() {
    if command_exists trivy; then
        echo -e "${GREEN}Running Trivy container scanning...${NC}"
        
        # Scan common base images
        local images=("python:3.11-slim" "ubuntu:22.04" "jupyter/datascience-notebook:latest")
        
        for image in "${images[@]}"; do
            echo -e "${GREEN}Scanning image: $image${NC}"
            trivy image --format json --output "$OUTPUT_DIR/trivy_${image//[\/:]/_}_$DATE.json" "$image" || true
        done
        
        # Scan Dockerfiles if they exist
        find "$SCAN_DIR" -name "Dockerfile*" -type f | while read -r dockerfile; do
            echo -e "${GREEN}Scanning Dockerfile: $dockerfile${NC}"
            trivy config --format json --output "$OUTPUT_DIR/trivy_dockerfile_$(basename "$dockerfile")_$DATE.json" "$dockerfile" || true
        done
        
        echo -e "${GREEN}✓ Trivy scans completed${NC}"
    else
        echo -e "${YELLOW}⚠ Trivy not found, skipping container security scan${NC}"
    fi
}

# Terraform security scanning with tfsec
run_tfsec_scan() {
    if command_exists tfsec; then
        echo -e "${GREEN}Running tfsec Terraform security scan...${NC}"
        
        # Find Terraform directories
        find "$SCAN_DIR" -name "*.tf" -type f -exec dirname {} \; | sort -u | while read -r tf_dir; do
            echo -e "${GREEN}Scanning Terraform directory: $tf_dir${NC}"
            tfsec "$tf_dir" --format json --out "$OUTPUT_DIR/tfsec_$(basename "$tf_dir")_$DATE.json" || true
        done
        
        echo -e "${GREEN}✓ tfsec scan completed${NC}"
    else
        echo -e "${YELLOW}⚠ tfsec not found, skipping Terraform security scan${NC}"
    fi
}

# Secret scanning
run_secret_scan() {
    echo -e "${GREEN}Running secret detection scan...${NC}"
    
    # Basic regex patterns for common secrets
    local patterns=(
        "password.*=.*['\"][^'\"]{8,}['\"]"
        "api[_-]?key.*=.*['\"][^'\"]{16,}['\"]"
        "secret.*=.*['\"][^'\"]{16,}['\"]"
        "token.*=.*['\"][^'\"]{16,}['\"]"
        "private[_-]?key"
        "-----BEGIN.*PRIVATE KEY-----"
    )
    
    echo "# Secret Scan Report - $DATE" > "$OUTPUT_DIR/secret_scan_$DATE.txt"
    echo "# Scanning for potential secrets in: $SCAN_DIR" >> "$OUTPUT_DIR/secret_scan_$DATE.txt"
    echo "" >> "$OUTPUT_DIR/secret_scan_$DATE.txt"
    
    for pattern in "${patterns[@]}"; do
        echo "## Pattern: $pattern" >> "$OUTPUT_DIR/secret_scan_$DATE.txt"
        grep -r -i -E "$pattern" "$SCAN_DIR" --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=venv || true >> "$OUTPUT_DIR/secret_scan_$DATE.txt"
        echo "" >> "$OUTPUT_DIR/secret_scan_$DATE.txt"
    done
    
    echo -e "${GREEN}✓ Secret scan completed${NC}"
}

# Generate summary report
generate_summary() {
    echo -e "${GREEN}Generating security scan summary...${NC}"
    
    local summary_file="$OUTPUT_DIR/security_scan_summary_$DATE.md"
    
    cat > "$summary_file" << EOF
# Security Scan Summary

**Date:** $(date)
**Scan Directory:** $SCAN_DIR

## Reports Generated

EOF
    
    # List all generated reports
    ls -la "$OUTPUT_DIR"/*_$DATE.* >> "$summary_file" 2>/dev/null || echo "No reports generated" >> "$summary_file"
    
    echo -e "${GREEN}✓ Summary report generated: $summary_file${NC}"
}

# Main execution
main() {
    echo -e "${GREEN}=== Security Scanning Suite ===${NC}"
    
    # Check if we should install tools
    if [[ "${INSTALL_TOOLS:-false}" == "true" ]]; then
        install_security_tools
    fi
    
    # Run all scans
    run_bandit_scan
    run_safety_scan
    run_semgrep_scan
    run_trivy_scan
    run_tfsec_scan
    run_secret_scan
    
    # Generate summary
    generate_summary
    
    echo -e "${GREEN}=== Security scan completed ===${NC}"
    echo -e "${GREEN}Reports saved to: $OUTPUT_DIR${NC}"
    
    # Check for critical findings
    if grep -q "CRITICAL\|HIGH" "$OUTPUT_DIR"/*_$DATE.* 2>/dev/null; then
        echo -e "${RED}⚠ Critical or high severity issues found!${NC}"
        echo -e "${RED}Please review the reports in $OUTPUT_DIR${NC}"
        exit 1
    else
        echo -e "${GREEN}✓ No critical issues detected${NC}"
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --install-tools)
            INSTALL_TOOLS=true
            shift
            ;;
        --help)
            echo "Usage: $0 [SCAN_DIRECTORY] [--install-tools] [--help]"
            echo "  SCAN_DIRECTORY: Directory to scan (default: current directory)"
            echo "  --install-tools: Install missing security tools"
            echo "  --help: Show this help message"
            exit 0
            ;;
        *)
            SCAN_DIR="$1"
            shift
            ;;
    esac
done

# Run main function
main
