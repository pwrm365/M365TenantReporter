function Get-M365TRStoredTenants {
    <#
    .SYNOPSIS
    Reads the index of tenants that have app-only credentials configured
    (C:\data\M365TenantReporter\.credentials\tenants.json). Returns an empty array
    (never throws, never $null) when nothing is configured yet.
    #>
    [CmdletBinding()]
    param(
        [string]$Path = (Join-Path $PSScriptRoot '..\.credentials\tenants.json')
    )
    if (-not (Test-Path -LiteralPath $Path)) { return @() }
    try {
        $data = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
        return @($data)
    } catch {
        Write-Warning "Nie udało się odczytać listy tenantów: $($_.Exception.Message)"
        return @()
    }
}
