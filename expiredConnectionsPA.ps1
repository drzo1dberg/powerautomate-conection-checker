#Requires -Version 5.1
#Requires -Modules Microsoft.PowerApps.Administration.PowerShell

[CmdletBinding()]
param(
    [int]$MaxAgeDays = 90
)

try {
    # 1) Interaktive Anmeldung
    Add-PowerAppsAccount

    # 2) Verbindungen laden
    $connections = Get-AdminPowerAppConnection -ErrorAction Stop

    # Gemeinsame Variablen
    $now = Get-Date

    # ───── Section 1: Tatsächlich abgelaufene Connections ─────
    $expiredList = $connections | Where-Object {
        ($_.Statuses | Select-Object -ExpandProperty status) -contains 'Expired'
    }

    Write-Host "Total Connections: $($connections.Count)"
    if ($expiredList.Count -gt 0) {
        Write-Host "Expired Connections: $($expiredList.Count)" -ForegroundColor Red
        foreach ($conn in $expiredList) {
            Write-Host " - $($conn.DisplayName)" -ForegroundColor Red
        }
    } else {
        Write-Host "No expired connections." -ForegroundColor Green
    }
    $count = 0
    # ───── Section 2: „Stale“ Connections (LastModifiedTime > 90 Tage) ─────
    $staleList = $connections | Where-Object {

        # nur jene, die nicht bereits als Expired gelistet sind
        -not ( ($_.Statuses | Select-Object -ExpandProperty status) -contains 'Expired' ) -and
        ($now - [DateTime]$_.LastModifiedTime).Days -ge $MaxAgeDays
    }

    if ($staleList.Count -gt 0) {
        Write-Host "`nStale Connections total $count (no modification in last $MaxAgeDays days):" -ForegroundColor Yellow
        foreach ($conn in $staleList) {
            $count++
            Write-Host " - $($conn.DisplayName) (Last Modified: $([DateTime]$conn.LastModifiedTime))" -ForegroundColor Yellow
        }
    } else {
        Write-Host "`nNo stale connections." -ForegroundColor Green
    }
    Write-Host "`nTotal stale connections: $count" -ForegroundColor Yellow
}
catch {
    Write-Error "An error occurred: $_"
    exit 1
}
