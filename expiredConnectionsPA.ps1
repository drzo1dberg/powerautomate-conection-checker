#Requires -Version 5.1
#Requires -Modules Microsoft.PowerApps.Administration.PowerShell
#Requires -Modules Microsoft.PowerApps.PowerShell

try {
    # Service Principal Login
    $clientId = "YOUR_CLIENT_ID"
    $clientSecret = "YOUR_CLIENT_SECRET"
    $tenantId = "YOUR_TENANT_ID"
    
    Add-PowerAppsAccount -ApplicationId $clientId -ClientSecret $clientSecret -TenantId $tenantId

    # Alle Connections laden
    $connections = Get-AdminPowerAppConnection -ErrorAction Stop

    # Connections ohne Connected-Status filtern
    $errorList = $connections | Where-Object {
        -not (($_.Statuses | Select-Object -ExpandProperty status) -contains 'Connected')
    }

    Write-Host "Total Connections: $($connections.Count)"
    if ($errorList.Count -gt 0) {
        Write-Host "⚠️Connections without Connected status: $($errorList.Count)" -ForegroundColor Red
        foreach ($c in $errorList) {
           $st = ($c.Statuses | Select-Object -ExpandProperty status) -join ', '
           Write-Host " - $($c.DisplayName) (Status: $st)" -ForegroundColor Red
        }
        exit 1
    } else {
        Write-Host "All connections are connected" -ForegroundColor Green
        exit 0
    }
}
catch {
    Write-Error "An error occurred: $_"
    exit 1
}