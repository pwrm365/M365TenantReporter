function Save-M365TRExoConfig {
    <#
    .SYNOPSIS
    Persists the Exchange Online / Security & Compliance app-only config for a specific tenant.
    Not secret data - the certificate's private key stays in the Windows certificate store
    (Cert:\CurrentUser\My); this file only records which thumbprint/AppId/tenant domain to use.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$TenantId,
        [Parameter(Mandatory)][string]$Thumbprint,
        [Parameter(Mandatory)][string]$AppId,
        [Parameter(Mandatory)][string]$Organization,
        [string]$CredentialsDir = (Join-Path $PSScriptRoot '..\.credentials')
    )
    if (-not (Test-Path -LiteralPath $CredentialsDir)) { New-Item -ItemType Directory -Path $CredentialsDir -Force | Out-Null }
    $path = Join-Path $CredentialsDir "exoconfig_$TenantId.json"

    [PSCustomObject]@{
        Thumbprint   = $Thumbprint
        AppId        = $AppId
        Organization = $Organization
    } | Microsoft.PowerShell.Utility\ConvertTo-Json | Set-Content -LiteralPath $path -Encoding UTF8

    Write-Host "Konfiguracja Exchange Online zapisana: $path"
}
