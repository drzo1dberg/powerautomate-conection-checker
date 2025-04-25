#Requires -Version 5.1
#Requires -Modules Microsoft.PowerApps.Administration.PowerShell
#Requires -Modules Microsoft.PowerApps.PowerShell

[CmdletBinding()]
param(
    [int]$InactiveDays = 90,
    [int]$WarnLowerDays = 28,
    [int]$WarnUpperDays = 33
)

try {
    # Interaktive Anmeldung
    Add-PowerAppsAccount

    # Gemeinsame Variablen
    $now = Get-Date
    $inactiveCutoff  = $now.AddDays(-$InactiveDays)      # Ablaufschwelle (älter als 90 Tage = ignorieren)
    $warnLowerCutoff = $now.AddDays(-$WarnLowerDays)      # letzter Run älter als 28 Tage
    $warnUpperCutoff = $now.AddDays(-$WarnUpperDays)      # letzter Run jünger als 33 Tage

    # ───── Section 1: Aktive Flows ermitteln ─────
    $allFlows = Get-AdminFlow -ErrorAction Stop

    # ───── Section 2: Warnungs-Flows (28–33 Tage inaktiv) ─────
    $warnFlows = $allFlows | Where-Object {
        #last run holen
        $run = Get-FlowRun `
            -EnvironmentName $_.EnvironmentName `
            -FlowName $_.FlowName `
            -ErrorAction SilentlyContinue `
            | Sort-Object StartTime -Descending `
            | Select-Object -First 1 

        if (-not $run.StartTime) { return $false }
        $lr = [DateTime] $run.StartTime
        ($lr -lt $warnLowerCutoff) -and ($lr -gt $warnUpperCutoff)
    }

    Write-Host "Warnungs-Flows (letzter Run zwischen $WarnUpperDays und $WarnLowerDays Tagen): $($warnFlows.Count)" -ForegroundColor Yellow

    foreach ($flow in $warnFlows) {
        $lr = (Get-FlowRun -EnvironmentName $flow.EnvironmentName -FlowName $flow.FlowName | Sort-Object StartTime -Descending | Select-Object -First 1).StartTime
        Write-Host " - $($flow.DisplayName) (Last Run: $([DateTime]$lr))" -ForegroundColor Yellow
    }

    # ───── Section 3: Check-Flows (Run jünger als $InactiveDays Tage) ─────
    $checkFlows = $allFlows | Where-Object {
           #last run holen
        $run = Get-FlowRun `
            -EnvironmentName $_.EnvironmentName `
            -FlowName $_.FlowName `
            -ErrorAction SilentlyContinue `
            | Sort-Object StartTime -Descending `
            | Select-Object -First 1 

        if (-not $run.StartTime) {return $false}
        [DateTime]$run.StartTime -gt $inactiveCutoff
    }

    # ───── Section 4: Connection-IDs aus Check-Flows extrahieren ─────
    $connectionIds = $checkFlows | 
        ForEach-Object {
            $_.Properties.definition.connectionReferences.Values
        } | 
        Select-Object -Unique

    # ───── Section 5: Verbindungen laden und auf relevante IDs filtern ─────
    $connections = Get-AdminPowerAppConnection -ErrorAction Stop |
        Where-Object { $connectionIds -contains $_.Name } 

    # ───── Section 6: Expired-Connections ─────
    $expiredList = $connections | Where-Object {
           -not (($_.Statuses | Select-Object -ExpandProperty status) -contains 'Connected')
    }
    Write-Host "Total Connections: $($connections.Count)"
    if ($expiredList.Count -gt 0) {
        Write-Host "⚠️Possibly Expired: $($expiredList.Count)" -ForegroundColor Red
        foreach ($c in $expiredList) {
           $st = ($c.Statuses | Select-Object -ExpandProperty status) -join ', '
           Write-Host " - $($c.DisplayName) (Status: $st)" -ForegroundColor Red
        }
    } else {
        Write-Host "No expired connections" -ForegroundColor Green
    }
    # ───── Section 7: Stale-Connections (LastModifiedTime ≥ $InactiveDays Tage) ─────
    $staleList = $connections | Where-Object {
        -not (($_.Statuses | Select-Object -ExpandProperty status) -contains 'Connected')
        -and
        ($now - [DateTime]$_.LastModifiedTime).Days -ge $InactiveDays
    }
    if ($staleList.Count -gt 0) {
        Write-Host "⚠️ Stale Connections (no modification in last $InactiveDays days):" -ForegroundColor Yellow
        foreach ($c in $staleList) {
            Write-Host " - $($c.DisplayName) (Last Modified: $([DateTime]$c.LastModifiedTime))" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "✅ No stale connections." -ForegroundColor Green
    }
}
catch {
    Write-Error "An error occurred: $_"
    exit 1
}