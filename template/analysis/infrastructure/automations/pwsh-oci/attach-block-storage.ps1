<#
.SYNOPSIS
    Attach block storage to a running OCI virtual machine
.DESCRIPTION
    This script attaches a block volume to a running compute instance in Oracle Cloud Infrastructure
.PARAMETER InstanceId
    The OCID of the compute instance to attach storage to
.PARAMETER VolumeId
    The OCID of the block volume to attach
.PARAMETER Region
    The OCI region where the resources are located
.PARAMETER AttachmentType
    Type of attachment (iscsi, paravirtualized, or emulated)
.PARAMETER DeviceName
    Device name for the attachment (optional)
.PARAMETER IsReadOnly
    Whether to attach as read-only (default: false)
.EXAMPLE
    .\attach-block-storage.ps1 -InstanceId "ocid1.instance..." -VolumeId "ocid1.volume..." -Region "us-phoenix-1"
.NOTES
    Requires OCI CLI to be installed and configured
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$InstanceId,

    [Parameter(Mandatory=$true)]
    [string]$VolumeId,

    [Parameter(Mandatory=$false)]
    [string]$Region,

    [Parameter(Mandatory=$false)]
    [ValidateSet("iscsi", "paravirtualized", "emulated")]
    [string]$AttachmentType = "paravirtualized",

    [Parameter(Mandatory=$false)]
    [string]$DeviceName,

    [Parameter(Mandatory=$false)]
    [bool]$IsReadOnly = $false,

    [Parameter(Mandatory=$false)]
    [switch]$WaitForCompletion,

    [Parameter(Mandatory=$false)]
    [switch]$ShowCommands
)

# Function to check if OCI CLI is available
function Test-OCICLIAvailable {
    try {
        $null = Get-Command "oci" -ErrorAction Stop
        return $true
    }
    catch {
        Write-Error "OCI CLI not found. Please install it from: https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm"
        return $false
    }
}

# Function to validate OCID format
function Test-OCID {
    param([string]$OCID, [string]$Type)

    if ($OCID -notmatch "^ocid1\.$Type\.") {
        Write-Error "Invalid $Type OCID format: $OCID"
        return $false
    }
    return $true
}

# Function to get instance details
function Get-InstanceDetails {
    param([string]$InstanceId, [string]$Region)

    try {
        $regionParam = if ($Region) { "--region $Region" } else { "" }
        $cmd = "oci compute instance get --instance-id $InstanceId $regionParam"

        if ($ShowCommands) { Write-Host "Executing: $cmd" -ForegroundColor Cyan }

        $result = Invoke-Expression $cmd | ConvertFrom-Json
        return $result.data
    }
    catch {
        Write-Error "Failed to get instance details: $($_.Exception.Message)"
        return $null
    }
}

# Function to get volume details
function Get-VolumeDetails {
    param([string]$VolumeId, [string]$Region)

    try {
        $regionParam = if ($Region) { "--region $Region" } else { "" }
        $cmd = "oci bv volume get --volume-id $VolumeId $regionParam"

        if ($ShowCommands) { Write-Host "Executing: $cmd" -ForegroundColor Cyan }

        $result = Invoke-Expression $cmd | ConvertFrom-Json
        return $result.data
    }
    catch {
        Write-Error "Failed to get volume details: $($_.Exception.Message)"
        return $null
    }
}

# Function to attach volume to instance
function Attach-VolumeToInstance {
    param(
        [string]$InstanceId,
        [string]$VolumeId,
        [string]$Region,
        [string]$AttachmentType,
        [string]$DeviceName,
        [bool]$IsReadOnly
    )

    try {
        # Build the attachment command
        $regionParam = if ($Region) { "--region $Region" } else { "" }
        $deviceParam = if ($DeviceName) { "--device $DeviceName" } else { "" }
        $readOnlyParam = if ($IsReadOnly) { "--is-read-only true" } else { "--is-read-only false" }

        $cmd = "oci compute volume-attachment attach --instance-id $InstanceId --volume-id $VolumeId --type $AttachmentType $deviceParam $readOnlyParam $regionParam"

        if ($ShowCommands) { Write-Host "Executing: $cmd" -ForegroundColor Cyan }

        Write-Host "Attaching volume to instance..." -ForegroundColor Yellow
        $result = Invoke-Expression $cmd | ConvertFrom-Json

        return $result.data
    }
    catch {
        Write-Error "Failed to attach volume: $($_.Exception.Message)"
        return $null
    }
}

# Function to wait for attachment completion
function Wait-ForAttachmentCompletion {
    param([string]$AttachmentId, [string]$Region)

    Write-Host "Waiting for attachment to complete..." -ForegroundColor Yellow

    do {
        Start-Sleep -Seconds 10

        try {
            $regionParam = if ($Region) { "--region $Region" } else { "" }
            $cmd = "oci compute volume-attachment get --volume-attachment-id $AttachmentId $regionParam"

            $result = Invoke-Expression $cmd | ConvertFrom-Json
            $state = $result.data."lifecycle-state"

            Write-Host "Current state: $state" -ForegroundColor Cyan

            if ($state -eq "ATTACHED") {
                Write-Host "Volume successfully attached!" -ForegroundColor Green
                return $result.data
            }
            elseif ($state -eq "ATTACHING") {
                Write-Host "Still attaching..." -ForegroundColor Yellow
            }
            else {
                Write-Error "Unexpected state: $state"
                return $null
            }
        }
        catch {
            Write-Error "Failed to check attachment status: $($_.Exception.Message)"
            return $null
        }
    } while ($true)
}

# Function to display attachment instructions
function Show-AttachmentInstructions {
    param($AttachmentDetails, $AttachmentType)

    Write-Host "`n=== POST-ATTACHMENT INSTRUCTIONS ===" -ForegroundColor Green

    if ($AttachmentType -eq "iscsi") {
        Write-Host "For iSCSI attachment, you need to configure iSCSI on the instance:" -ForegroundColor Yellow
        Write-Host "1. Connect to your instance via SSH" -ForegroundColor Cyan
        Write-Host "2. Install iSCSI utilities if not present:" -ForegroundColor Cyan
        Write-Host "   sudo yum install iscsi-initiator-utils -y (for OL/RHEL)" -ForegroundColor Gray
        Write-Host "   sudo apt-get install open-iscsi -y (for Ubuntu)" -ForegroundColor Gray
        Write-Host "3. Use the iSCSI commands provided in the OCI console" -ForegroundColor Cyan

        if ($AttachmentDetails."iscsi-attach-commands") {
            Write-Host "`nRun these commands on your instance:" -ForegroundColor Yellow
            foreach ($cmd in $AttachmentDetails."iscsi-attach-commands") {
                Write-Host "   $cmd" -ForegroundColor Gray
            }
        }
    }
    elseif ($AttachmentType -eq "paravirtualized") {
        Write-Host "For paravirtualized attachment:" -ForegroundColor Yellow
        Write-Host "1. Connect to your instance via SSH" -ForegroundColor Cyan
        Write-Host "2. Check for the new device: lsblk" -ForegroundColor Cyan
        Write-Host "3. Create filesystem: sudo mkfs.ext4 /dev/sdb (adjust device name)" -ForegroundColor Cyan
        Write-Host "4. Mount the volume: sudo mount /dev/sdb /mnt/data" -ForegroundColor Cyan
    }

    Write-Host "`nDevice information:" -ForegroundColor Yellow
    if ($AttachmentDetails.device) {
        Write-Host "Device: $($AttachmentDetails.device)" -ForegroundColor Cyan
    }
    Write-Host "Attachment ID: $($AttachmentDetails.id)" -ForegroundColor Cyan
}

# Main execution
try {
    Write-Host "=== OCI Block Storage Attachment Tool ===" -ForegroundColor Green

    # Check prerequisites
    if (-not (Test-OCICLIAvailable)) {
        exit 1
    }

    # Validate OCIDs
    if (-not (Test-OCID -OCID $InstanceId -Type "instance")) {
        exit 1
    }

    if (-not (Test-OCID -OCID $VolumeId -Type "volume")) {
        exit 1
    }

    Write-Host "Validating instance and volume..." -ForegroundColor Yellow

    # Get instance details
    $instance = Get-InstanceDetails -InstanceId $InstanceId -Region $Region
    if (-not $instance) {
        Write-Error "Could not retrieve instance details"
        exit 1
    }

    # Get volume details
    $volume = Get-VolumeDetails -VolumeId $VolumeId -Region $Region
    if (-not $volume) {
        Write-Error "Could not retrieve volume details"
        exit 1
    }

    # Validate states
    if ($instance."lifecycle-state" -ne "RUNNING") {
        Write-Error "Instance is not in RUNNING state. Current state: $($instance.'lifecycle-state')"
        exit 1
    }

    if ($volume."lifecycle-state" -ne "AVAILABLE") {
        Write-Error "Volume is not in AVAILABLE state. Current state: $($volume.'lifecycle-state')"
        exit 1
    }

    # Validate same availability domain (for paravirtualized)
    if ($AttachmentType -eq "paravirtualized" -and $instance."availability-domain" -ne $volume."availability-domain") {
        Write-Error "For paravirtualized attachment, instance and volume must be in the same availability domain"
        Write-Host "Instance AD: $($instance.'availability-domain')" -ForegroundColor Yellow
        Write-Host "Volume AD: $($volume.'availability-domain')" -ForegroundColor Yellow
        exit 1
    }

    # Display summary
    Write-Host "`n=== ATTACHMENT SUMMARY ===" -ForegroundColor Green
    Write-Host "Instance: $($instance.'display-name') ($($instance.'lifecycle-state'))" -ForegroundColor Cyan
    Write-Host "Volume: $($volume.'display-name') ($($volume.'size-in-gbs') GB, $($volume.'lifecycle-state'))" -ForegroundColor Cyan
    Write-Host "Attachment Type: $AttachmentType" -ForegroundColor Cyan
    Write-Host "Read Only: $IsReadOnly" -ForegroundColor Cyan
    if ($DeviceName) {
        Write-Host "Device Name: $DeviceName" -ForegroundColor Cyan
    }

    # Confirm attachment
    $confirmation = Read-Host "`nProceed with attachment? (y/N)"
    if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
        Write-Host "Attachment cancelled by user" -ForegroundColor Yellow
        exit 0
    }

    # Perform attachment
    $attachment = Attach-VolumeToInstance -InstanceId $InstanceId -VolumeId $VolumeId -Region $Region -AttachmentType $AttachmentType -DeviceName $DeviceName -IsReadOnly $IsReadOnly

    if (-not $attachment) {
        Write-Error "Failed to initiate volume attachment"
        exit 1
    }

    Write-Host "`nAttachment initiated successfully!" -ForegroundColor Green
    Write-Host "Attachment ID: $($attachment.id)" -ForegroundColor Cyan
    Write-Host "Initial State: $($attachment.'lifecycle-state')" -ForegroundColor Cyan

    # Wait for completion if requested
    if ($WaitForCompletion) {
        $finalAttachment = Wait-ForAttachmentCompletion -AttachmentId $attachment.id -Region $Region

        if ($finalAttachment) {
            Show-AttachmentInstructions -AttachmentDetails $finalAttachment -AttachmentType $AttachmentType
        }
    } else {
        Write-Host "`nUse -WaitForCompletion to wait for attachment to complete" -ForegroundColor Yellow
        Write-Host "Or check status manually with:" -ForegroundColor Yellow
        $regionParam = if ($Region) { " --region $Region" } else { "" }
        Write-Host "oci compute volume-attachment get --volume-attachment-id $($attachment.id)$regionParam" -ForegroundColor Gray
    }

} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    exit 1
}

Write-Host "`n=== Script completed ===" -ForegroundColor Green
