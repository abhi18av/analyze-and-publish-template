<#
.SYNOPSIS
    Inspect active VMs across all OCI regions using PowerShell toolkit
.DESCRIPTION
    This script queries all OCI regions to find active compute instances and provides a summary
.NOTES
    Requires OCI PowerShell module: Install-Module OCI.PSModules
#>

# Function to install OCI PowerShell modules if not present
function Install-OCIModules {
    # Check if OCI CLI is available as fallback
    $ociCliAvailable = $false
    try {
        $null = Get-Command "oci" -ErrorAction Stop
        $ociCliAvailable = $true
        Write-Host "OCI CLI found - can use as fallback" -ForegroundColor Green
    }
    catch {
        Write-Host "OCI CLI not found" -ForegroundColor Yellow
    }

    # Try to find OCI PowerShell modules
    $availableOCIModules = Get-Module -ListAvailable | Where-Object { $_.Name -like "OCI*" }

    if ($availableOCIModules.Count -eq 0) {
        Write-Host "No OCI PowerShell modules found." -ForegroundColor Yellow

        if ($ociCliAvailable) {
            Write-Host "Will use OCI CLI instead of PowerShell modules" -ForegroundColor Cyan
            return "CLI"
        } else {
            Write-Error "Neither OCI PowerShell modules nor OCI CLI found."
            Write-Host "Please install one of the following:" -ForegroundColor Yellow
            Write-Host "1. OCI CLI: https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm" -ForegroundColor Cyan
            Write-Host "2. OCI PowerShell (if available): Install-Module OCI.PSModules" -ForegroundColor Cyan
            return $false
        }
    } else {
        Write-Host "Found OCI modules: $($availableOCIModules.Name -join ', ')" -ForegroundColor Green
        return "POWERSHELL"
    }
}

# Check and install OCI PowerShell modules
Write-Host "Checking OCI PowerShell modules..." -ForegroundColor Cyan
$ociMethod = Install-OCIModules

if ($ociMethod -eq $false) {
    exit 1
} elseif ($ociMethod -eq "CLI") {
    Write-Host "Using OCI CLI instead of PowerShell modules" -ForegroundColor Cyan
    $useOCICLI = $true
} else {
    Write-Host "Using OCI PowerShell modules" -ForegroundColor Cyan
    $useOCICLI = $false

    # Try to import available OCI modules
    $availableOCIModules = Get-Module -ListAvailable | Where-Object { $_.Name -like "OCI*" }
    foreach ($module in $availableOCIModules) {
        try {
            Import-Module $module.Name -ErrorAction Stop
            Write-Host "Imported: $($module.Name)" -ForegroundColor Green
        }
        catch {
            Write-Warning "Failed to import $($module.Name): $($_.Exception.Message)"
        }
    }
}

# Function to get all regions using OCI CLI
function Get-OCIRegionsWithCLI {
    try {
        $regionsJson = oci iam region-subscription list --all | ConvertFrom-Json
        return $regionsJson.data
    }
    catch {
        Write-Error "Failed to get regions with OCI CLI: $($_.Exception.Message)"
        return @()
    }
}

# Function to get all regions
function Get-OCIRegions {
    if ($useOCICLI) {
        return Get-OCIRegionsWithCLI
    } else {
        try {
            $regions = Get-OCIRegionSubscriptionsList -CompartmentId $tenancyId
            return $regions.Items
        }
        catch {
            Write-Error "Failed to get regions: $($_.Exception.Message)"
            return @()
        }
    }
}

# Function to get active instances in a region using OCI CLI
function Get-ActiveInstancesInRegionWithCLI {
    param(
        [string]$RegionName,
        [string]$CompartmentId
    )

    try {
        # Get all compartments
        $compartmentsJson = oci iam compartment list --compartment-id $CompartmentId --compartment-id-in-subtree true --all --region $RegionName | ConvertFrom-Json

        $activeInstances = @()

        foreach ($compartment in $compartmentsJson.data) {
            try {
                # Get instances in RUNNING state
                $instancesJson = oci compute instance list --compartment-id $compartment.id --lifecycle-state RUNNING --region $RegionName | ConvertFrom-Json

                foreach ($instance in $instancesJson.data) {
                    $activeInstances += [PSCustomObject]@{
                        Region = $RegionName
                        CompartmentName = $compartment.name
                        CompartmentId = $compartment.id
                        InstanceId = $instance.id
                        DisplayName = $instance."display-name"
                        Shape = $instance.shape
                        State = $instance."lifecycle-state"
                        TimeCreated = $instance."time-created"
                        AvailabilityDomain = $instance."availability-domain"
                        ImageId = $instance."image-id"
                    }
                }
            }
            catch {
                Write-Warning "Failed to get instances in compartment $($compartment.name) in region $RegionName : $($_.Exception.Message)"
            }
        }

        return $activeInstances
    }
    catch {
        Write-Error "Failed to get instances in region ${RegionName} with CLI: $($_.Exception.Message)"
        return @()
    }
}

# Function to get active instances in a region
function Get-ActiveInstancesInRegion {
    param(
        [string]$RegionName,
        [string]$CompartmentId
    )

    if ($useOCICLI) {
        return Get-ActiveInstancesInRegionWithCLI -RegionName $RegionName -CompartmentId $CompartmentId
    } else {
        try {
            # Set region for OCI client
            Set-OCIClientRegion -Region $RegionName

            # Get all compartments in the tenancy (including root and sub-compartments)
            $compartments = @()
            $compartments += Get-OCICompartment -CompartmentId $CompartmentId -AccessLevel ACCESSIBLE -CompartmentIdInSubtree $true

            $activeInstances = @()

            foreach ($compartment in $compartments.Items) {
                try {
                    # Get instances in RUNNING state
                    $instances = Get-OCIComputeInstancesList -CompartmentId $compartment.Id -LifecycleState RUNNING

                    foreach ($instance in $instances.Items) {
                        $activeInstances += [PSCustomObject]@{
                            Region = $RegionName
                            CompartmentName = $compartment.Name
                            CompartmentId = $compartment.Id
                            InstanceId = $instance.Id
                            DisplayName = $instance.DisplayName
                            Shape = $instance.Shape
                            State = $instance.LifecycleState
                            TimeCreated = $instance.TimeCreated
                            AvailabilityDomain = $instance.AvailabilityDomain
                            ImageId = $instance.ImageId
                        }
                    }
                }
                catch {
                    Write-Warning "Failed to get instances in compartment $($compartment.Name) in region $RegionName : $($_.Exception.Message)"
                }
            }

            return $activeInstances
        }
        catch {
            Write-Error "Failed to get instances in region ${RegionName}: $($_.Exception.Message)"
            return @()
        }
    }
}

# Function to get instance details including networking
function Get-InstanceNetworkDetails {
    param(
        [string]$InstanceId,
        [string]$CompartmentId
    )

    try {
        # Get VNIC attachments
        $vnicAttachments = Get-OCIComputeVnicAttachmentsList -CompartmentId $CompartmentId -InstanceId $InstanceId

        $networkDetails = @()
        foreach ($attachment in $vnicAttachments.Items) {
            if ($attachment.LifecycleState -eq "ATTACHED") {
                $vnic = Get-OCICoreVnic -VnicId $attachment.VnicId
                $networkDetails += [PSCustomObject]@{
                    VnicId = $vnic.Id
                    PrivateIp = $vnic.PrivateIp
                    PublicIp = $vnic.PublicIp
                    SubnetId = $vnic.SubnetId
                    IsPrimary = $attachment.IsPrimary
                }
            }
        }

        return $networkDetails
    }
    catch {
        Write-Warning "Failed to get network details for instance $InstanceId : $($_.Exception.Message)"
        return @()
    }
}

# Main execution
try {
    Write-Host "=== OCI Active VM Inspector ===" -ForegroundColor Green
    Write-Host "Initializing OCI session..." -ForegroundColor Yellow

    if ($useOCICLI) {
        # Using OCI CLI - get tenancy from config
        try {
            $tenancyInfo = oci iam tenancy get --tenancy-id (oci iam tenancy get --tenancy-id $(oci setup config-validation | Select-String "tenancy" | ForEach-Object { ($_ -split ":")[1].Trim() }) | ConvertFrom-Json).data.id | ConvertFrom-Json
            $tenancyId = $tenancyInfo.data.id
        }
        catch {
            # Simpler approach - try to get tenancy from current user info
            try {
                $userInfo = oci iam user get --user-id (oci iam user list --compartment-id (oci iam compartment list --compartment-id-in-subtree false --limit 1 | ConvertFrom-Json).data[0]."compartment-id" --limit 1 | ConvertFrom-Json).data[0].id | ConvertFrom-Json
                $tenancyId = $userInfo.data."compartment-id"
            }
            catch {
                # Final fallback - extract from config file
                try {
                    $configPath = "$HOME/.oci/config"
                    if (Test-Path $configPath) {
                        $configContent = Get-Content $configPath
                        $tenancyLine = $configContent | Where-Object { $_ -match "^tenancy\s*=" }
                        if ($tenancyLine) {
                            $tenancyId = ($tenancyLine -split "=")[1].Trim()
                        } else {
                            throw "Tenancy not found in config"
                        }
                    } else {
                        throw "OCI config file not found"
                    }
                }
                catch {
                    Write-Error "Failed to get tenancy ID. Please ensure OCI CLI is configured properly with: oci setup config"
                    exit 1
                }
            }
        }
    } else {
        # Check if PowerShell functions are actually available
        if (Get-Command "Initialize-OCISession" -ErrorAction SilentlyContinue) {
            # Initialize OCI session (assumes profile is configured)
            Initialize-OCISession
            # Get tenancy ID from current session
            $tenancyId = (Get-OCIConfigData).Tenancy
        } else {
            Write-Warning "PowerShell OCI functions not available, falling back to OCI CLI"
            $useOCICLI = $true
            # Retry with CLI method
            $configPath = "$HOME/.oci/config"
            if (Test-Path $configPath) {
                $configContent = Get-Content $configPath
                $tenancyLine = $configContent | Where-Object { $_ -match "^tenancy\s*=" }
                if ($tenancyLine) {
                    $tenancyId = ($tenancyLine -split "=")[1].Trim()
                } else {
                    Write-Error "Tenancy not found in OCI config file"
                    exit 1
                }
            } else {
                Write-Error "OCI config file not found at $configPath"
                exit 1
            }
        }
    }

    Write-Host "Using Tenancy ID: $tenancyId" -ForegroundColor Cyan

    # Get all regions
    Write-Host "Fetching available regions..." -ForegroundColor Yellow
    $regions = Get-OCIRegions

    if ($regions.Count -eq 0) {
        Write-Error "No regions found. Please check your OCI configuration."
        exit 1
    }

    Write-Host "Found $($regions.Count) regions to check" -ForegroundColor Cyan

    # Collect all active instances
    $allActiveInstances = @()
    $regionSummary = @()

    foreach ($region in $regions) {
        $regionName = if ($useOCICLI) { $region."region-name" } else { $region.RegionName }
        Write-Host "Checking region: $regionName..." -ForegroundColor Yellow

        $instances = Get-ActiveInstancesInRegion -RegionName $regionName -CompartmentId $tenancyId

        if ($instances.Count -gt 0) {
            $allActiveInstances += $instances

            $regionSummary += [PSCustomObject]@{
                Region = $regionName
                ActiveInstances = $instances.Count
                Shapes = ($instances | Group-Object Shape | ForEach-Object { "$($_.Name) ($($_.Count))" }) -join ", "
            }

            Write-Host "  Found $($instances.Count) active instances" -ForegroundColor Green
        } else {
            Write-Host "  No active instances found" -ForegroundColor Gray
        }
    }

    # Display summary
    Write-Host "`n=== SUMMARY ===" -ForegroundColor Green
    Write-Host "Total active instances across all regions: $($allActiveInstances.Count)" -ForegroundColor Cyan

    if ($regionSummary.Count -gt 0) {
        Write-Host "`nInstances by Region:" -ForegroundColor Yellow
        $regionSummary | Format-Table -AutoSize

        Write-Host "`nDetailed Instance List:" -ForegroundColor Yellow
        $allActiveInstances | Format-Table -Property Region, CompartmentName, DisplayName, Shape, State, TimeCreated -AutoSize

        # # Export to CSV for further analysis
        # $csvPath = "oci-active-instances-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
        # $allActiveInstances | Export-Csv -Path $csvPath -NoTypeInformation
        # Write-Host "Detailed report exported to: $csvPath" -ForegroundColor Green

        # Optional: Get network details for each instance (only works with PowerShell modules)
        if (-not $useOCICLI) {
            $getNetworkDetails = Read-Host "Do you want to fetch network details for all instances? (y/N)"
            if ($getNetworkDetails -eq 'y' -or $getNetworkDetails -eq 'Y') {
                Write-Host "Fetching network details..." -ForegroundColor Yellow

                $detailedReport = @()
                foreach ($instance in $allActiveInstances) {
                    if (Get-Command "Set-OCIClientRegion" -ErrorAction SilentlyContinue) {
                        Set-OCIClientRegion -Region $instance.Region
                        $networkDetails = Get-InstanceNetworkDetails -InstanceId $instance.InstanceId -CompartmentId $instance.CompartmentId

                        foreach ($network in $networkDetails) {
                            $detailedReport += [PSCustomObject]@{
                                Region = $instance.Region
                                CompartmentName = $instance.CompartmentName
                                InstanceName = $instance.DisplayName
                                Shape = $instance.Shape
                                PrivateIP = $network.PrivateIp
                                PublicIP = $network.PublicIp
                                IsPrimary = $network.IsPrimary
                            }
                        }
                    }
                }

                $detailedCsvPath = "oci-instances-with-network-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
                $detailedReport | Export-Csv -Path $detailedCsvPath -NoTypeInformation
                Write-Host "Detailed network report exported to: $detailedCsvPath" -ForegroundColor Green
            }
        } else {
            Write-Host "Network details require PowerShell modules (not available with OCI CLI method)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "No active instances found in any region." -ForegroundColor Yellow
    }

} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    exit 1
}

Write-Host "`n=== Script completed ===" -ForegroundColor Green
