#!/bin/bash

# Utility script to check infrastructure status

DATE=$(date +%Y-%m-%d)
LOGFILE="infrastructure_status_$DATE.log"

# Function to log messages
log_message() {
    MSG_TYPE="$1"
    MSG="$2"
    echo "[$(date +%Y-%m-%dT%H:%M:%S%z)] [$MSG_TYPE] $MSG" | tee -a "$LOGFILE"
}

log_message "INFO" "Checking infrastructure status..."

# Check Terraform status
if [ -d "terraform/local-multipass-vm" ]; then
    cd terraform/local-multipass-vm
    INIT_OUTPUT=$(terraform init -input=false)
    if [[ "$INIT_OUTPUT" == *"Terraform has been successfully initialized"* ]]; then
        PLAN_OUTPUT=$(terraform plan)
        echo "$PLAN_OUTPUT" | tee "../../$LOGFILE"
        log_message "INFO" "Terraform plan completed successfully."
    else
        log_message "ERROR" "Terraform initialization failed."
    fi
    cd -
else
    log_message "WARNING" "Terraform directory not found."
fi

# Check Docker status
docker ps | tee -a "$LOGFILE"
log_message "INFO" "Docker containers running: $(docker ps -q | wc -l)"

# Check Kubernetes status (if applicable)
if command -v kubectl &> /dev/null
then
    kubectl get nodes | tee -a "$LOGFILE"
    kubectl get pods --all-namespaces | tee -a "$LOGFILE"
    log_message "INFO" "Kubernetes cluster status retrieved."
else
    log_message "WARNING" "kubectl command not found; skipping Kubernetes check."
fi

# Check Multipass status
if command -v multipass &> /dev/null
then
    multipass list | tee -a "$LOGFILE"
    log_message "INFO" "Multipass instances listed."
else
    log_message "WARNING" "multipass command not found; skipping Multipass check."
fi

log_message "INFO" "Infrastructure status check completed."

exit 0

