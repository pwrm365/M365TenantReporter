function Get-M365TRStoredExoConfig {
    <#
    .SYNOPSIS
    Reads the Exchange Online / Security & Compliance app-only config (cert thumbprint,
    AppId, tenant .onmicrosoft.com domain) for a specific tenant, saved by Save-M365TRExoConfig.
    No secrets here - the certificate's private key lives in the Windows certificate store,
    not this file. Returns $null (never throws) when nothing is stored for that TenantId.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$TenantId,
        [string]$CredentialsDir = (Join-Path $PSScriptRoot '..\.credentials')
    )
    $path = Join-Path $CredentialsDir "exoconfig_$TenantId.json"
    if (-not (Test-Path -LiteralPath $path)) { return $null }
    try {
        Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
    } catch {
        Write-Warning "Nie udało się odczytać konfiguracji Exchange Online dla tenanta ${TenantId}: $($_.Exception.Message)"
        $null
    }
}
