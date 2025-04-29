# 1) Sicherstellen, dass PSGallery vertraut ist
if ((Get-PSRepository -Name PSGallery).InstallationPolicy -ne 'Trusted') {
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
}

# 2) NuGet-Paketprovider (für Install-Module) ohne Prompt installieren
if (-not (Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue)) {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.208 -Force
}

# 3) Module nur dann installieren, wenn sie fehlen
$modules = @(
    'Microsoft.PowerApps.PowerShell',
    'Microsoft.PowerApps.Administration.PowerShell'
)
foreach ($m in $modules) {
    if (-not (Get-Module -ListAvailable -Name $m)) {
        Install-Module `
            -Name $m `
            -Scope CurrentUser `
            -Force `
            -AllowClobber `
            -SkipPublisherCheck `
            -Confirm:$false `
            -ErrorAction Stop
    }
}

# 4) Module importieren (ErrorAction Stop sorgt dafür, dass dein Catch-Block greift)
Import-Module Microsoft.PowerApps.PowerShell   -ErrorAction Stop
Import-Module Microsoft.PowerApps.Administration.PowerShell -ErrorAction Stop

try {
    # Service Principal Login
    #$clientId = ""
    #$clientSecret = ""
    #$tenantId = ""
    
    Add-PowerAppsAccount -ApplicationId $clientId -ClientSecret $clientSecret -TenantId $tenantId

    # Alle Connections laden
    $connections = Get-AdminPowerAppConnection -ErrorAction Stop

    # Connections ohne Connected-Status filtern
    $errorList = $connections | Where-Object {
        -not (($_.Statuses | Select-Object -ExpandProperty status) -contains 'Connected')
    }

    Write-Host "Total Connections: $($connections.Count)"
    if ($errorList.Count -gt 0) {
        Write-Host "Connections without Connected status: $($errorList.Count)" -ForegroundColor Red
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