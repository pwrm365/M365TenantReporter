function Add-M365TRStoredTenant {
    <#
    .SYNOPSIS
    Adds or updates one entry in the tenants index (C:\data\M365TenantReporter\.credentials\tenants.json).
    Matches existing entries by TenantId so re-running setup for the same tenant updates it in place
    instead of creating a duplicate row.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$TenantId,
        [Parameter(Mandatory)][string]$DisplayName,
        [Parameter(Mandatory)][string]$Organization,
        [string]$Path = (Join-Path $PSScriptRoot '..\.credentials\tenants.json')
    )
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

    $existing = @(Get-M365TRStoredTenants -Path $Path)
    $others = @($existing | Where-Object { $_.TenantId -ne $TenantId })
    $updated = @($others) + [PSCustomObject]@{
        TenantId     = $TenantId
        DisplayName  = $DisplayName
        Organization = $Organization
    }
    Microsoft.PowerShell.Utility\ConvertTo-Json -InputObject @($updated) -Depth 4 | Set-Content -LiteralPath $Path -Encoding UTF8
}
