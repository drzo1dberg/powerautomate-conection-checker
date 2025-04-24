#Requires -Version 5.1
#Requires -Modules Microsoft.PowerApps.Administration.PowerShell

[CmdletBinding()]
param()

# Function to check if a connection is expired or soon to expire
function Test-ConnectionExpiry {
    param (
        [Parameter(Mandatory = $true)]
        [DateTime]$ExpiryDate
    )
    
    $now = Get-Date
    $daysUntilExpiry = ($ExpiryDate - $now).Days
    
    if ($daysUntilExpiry -lt 0) {
        return "EXPIRED"
    }
    elseif ($daysUntilExpiry -le 30) {
        return "SOON_TO_EXPIRE"
    }
    return "VALID"
}

# Function to format the output with color coding
function Write-ConnectionStatus {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Status,
        
        [Parameter(Mandatory = $true)]
        [string]$ConnectionName,
        
        [Parameter(Mandatory = $true)]
        [DateTime]$ExpiryDate
    )
    
    $expiryDateStr = $ExpiryDate.ToString("yyyy-MM-dd")
    
    switch ($Status) {
        "EXPIRED" {
            Write-Host "❌ EXPIRED: $ConnectionName (Expired on: $expiryDateStr)" -ForegroundColor Red
        }
        "SOON_TO_EXPIRE" {
            Write-Host "⚠️  SOON TO EXPIRE: $ConnectionName (Expires on: $expiryDateStr)" -ForegroundColor Yellow
        }
        "VALID" {
            Write-Host "✅ VALID: $ConnectionName (Expires on: $expiryDateStr)" -ForegroundColor Green
        }
    }
}

try {
    # Attempt to connect using interactive authentication
    Write-Host "Connecting to Power Apps Admin Center..." -ForegroundColor Cyan
    Add-PowerAppsAccount -UseDeviceAuthentication
    
    # Get all connections
    Write-Host "`nFetching Power App connections..." -ForegroundColor Cyan
    $connections = Get-AdminPowerAppConnection -ErrorAction Stop
    
    # Process and display connections
    Write-Host "`nConnection Status Report:" -ForegroundColor Cyan
    Write-Host "=======================" -ForegroundColor Cyan
    
    foreach ($connection in $connections) {
        $expiryStatus = Test-ConnectionExpiry -ExpiryDate $connection.ExpiryDate
        Write-ConnectionStatus -Status $expiryStatus -ConnectionName $connection.DisplayName -ExpiryDate $connection.ExpiryDate
    }
    
    # Summary
    $expiredCount = ($connections | Where-Object { $_.ExpiryDate -lt (Get-Date) }).Count
    $soonToExpireCount = ($connections | Where-Object { 
        $_.ExpiryDate -gt (Get-Date) -and 
        $_.ExpiryDate -lt (Get-Date).AddDays(30) 
    }).Count
    
    Write-Host "`nSummary:" -ForegroundColor Cyan
    Write-Host "=========" -ForegroundColor Cyan
    Write-Host "Total Connections: $($connections.Count)" -ForegroundColor White
    Write-Host "Expired Connections: $expiredCount" -ForegroundColor Red
    Write-Host "Soon to Expire (within 30 days): $soonToExpireCount" -ForegroundColor Yellow
    
}
catch {
    Write-Error "An error occurred: $_"
    Write-Host "`nPlease ensure you have the Microsoft.PowerApps.Administration.PowerShell module installed." -ForegroundColor Yellow
    Write-Host "You can install it using: Install-Module -Name Microsoft.PowerApps.Administration.PowerShell -Force" -ForegroundColor Yellow
    exit 1
}
