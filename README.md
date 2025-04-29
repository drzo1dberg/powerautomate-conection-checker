# Power Automate Connection Checker

A PowerShell script to monitor and report on Power Automate connection statuses in your Microsoft 365 environment.

## Features

- Checks all Power Automate connections for their status
- Identifies connections that are not in "Connected" state
- Uses Service Principal authentication for automated runs
- Returns appropriate exit codes for monitoring systems

## Prerequisites

- PowerShell 5.1 or later
- Microsoft.PowerApps.Administration.PowerShell module
- Microsoft.PowerApps.PowerShell module
- Service Principal with appropriate Power Platform API permissions

## Usage

1. Configure your Service Principal credentials:
```powershell
$clientId = "YOUR_CLIENT_ID"
$clientSecret = "YOUR_CLIENT_SECRET"
$tenantId = "YOUR_TENANT_ID"
```

2. Run the script:
```powershell
.\expiredConnectionsPA.ps1
```

## Output

The script will display:
- Total number of connections
- List of connections with non-Connected status
- Exit code 1 if any connections are not connected
- Exit code 0 if all connections are connected

## Exit Codes

- 0: All connections are connected
- 1: One or more connections are not connected

## License

MIT License
