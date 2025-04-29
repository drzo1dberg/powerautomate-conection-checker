# 1) check if the repository trusted
if ((Get-PSRepository -Name PSGallery).InstallationPolicy -ne 'Trusted') {
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
}

# 2) NuGet Packageprovider install
if (-not (Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue)) {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.208 -Force
}

# 3) only install modules that are not on the machine
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

# 4) Module import
Import-Module Microsoft.PowerApps.PowerShell -ErrorAction Stop
Import-Module Microsoft.PowerApps.Administration.PowerShell -ErrorAction Stop

try {
    # Service Principal Login
    #$clientId = ""
    #$clientSecret = ""
    #$tenantId = ""
    #$environmentIds ="'1cca0c87-e9c1-e620-a868-44759825b34b', 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee', 'ffffffff-1111-2222-3333-444444444444'"                                              
 
    Add-PowerAppsAccount -ApplicationId $clientId -ClientSecret $clientSecret -TenantId $tenantId 

    $environmentIds = $environmentIds -split ',' | ForEach-Object { $_.Trim(" '") }   

    # All Connections for this Environments                     
    $connections = foreach ($env in $environmentIds) {                     
        Get-AdminPowerAppConnection -EnvironmentName $env -ErrorAction Stop
    }                                                                      

    # filter connections without connected-status 
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
}
catch {
    Write-Error "An error occurred: $_"
    exit 1
}