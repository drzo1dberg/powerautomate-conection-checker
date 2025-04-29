# Power Automate Connection Checker

A PowerShell script to monitor and report on Power Automate connection statuses in your Microsoft 365 environment.

## Features

- Checks connections across multiple environments
- Identifies connections that are not in "Connected" state
- Uses Service Principal authentication for automation
- Returns appropriate exit codes for integration into monitoring systems

## Prerequisites

- PowerShell 5.1 or later
- Modules:
  - Microsoft.PowerApps.PowerShell
  - Microsoft.PowerApps.Administration.PowerShell
- A Service Principal with Power Platform admin permissions

## Setup

1. Make sure PSGallery is trusted:
```powershell
if ((Get-PSRepository -Name PSGallery).InstallationPolicy -ne 'Trusted') {
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
}
```

2. Install NuGet provider if necessary:
```powershell
if (-not (Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue)) {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.208 -Force
}
```

3. Install missing modules:
```powershell
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
```

4. Import modules:
```powershell
Import-Module Microsoft.PowerApps.PowerShell -ErrorAction Stop
Import-Module Microsoft.PowerApps.Administration.PowerShell -ErrorAction Stop
```

## Usage

1. Configure your Service Principal credentials:
```powershell
$clientId = "YOUR_CLIENT_ID"
$clientSecret = "YOUR_CLIENT_SECRET"
$tenantId = "YOUR_TENANT_ID"
$environmentIds = "'env1','env2','env3'"  # Comma-separated with single quotes
```

2. Run the script:
```powershell
$environmentIds = $environmentIds -split ',' | ForEach-Object { $_.Trim(" '") }

Add-PowerAppsAccount -ApplicationId $clientId -ClientSecret $clientSecret -TenantId $tenantId

$connections = foreach ($env in $environmentIds) {
    Get-AdminPowerAppConnection -EnvironmentName $env -ErrorAction Stop
}

$errorList = $connections | Where-Object {
    -not (($_.Statuses | Select-Object -ExpandProperty status) -contains 'Connected')
}

Write-Host "Total Connections: $($connections.Count)"

if ($errorList.Count -gt 0) {
    Write-Host "Connections without Connected status: $($errorList.Count)"
    foreach ($c in $errorList) {
        $st = ($c.Statuses | Select-Object -ExpandProperty status) -join ', '
        $line = "{0} | {1} | {2} | {3} | Status: {4}" -f `
            $c.DisplayName,
            $c.ConnectionName,
            $c.ConnectorName,
            $c.EnvironmentName,
            $st
        Write-Host " - $line"
    }
    exit 1
} else {
    Write-Host "All connections are connected"
    exit 0
}
```

## Output

- Summary count of total connections
- Details of any non-connected connections (name, connector, environment, status)
- Exit code 1 if any issues found
- Exit code 0 if all connections are healthy

## Exit Codes

- 0: All connections are connected
- 1: One or more connections are not connected

## License

MIT License

