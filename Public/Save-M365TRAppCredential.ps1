function Save-M365TRAppCredential {
    <#
    .SYNOPSIS
    Persists app-only credentials locally for a specific tenant (ClientSecret as a SecureString,
    DPAPI-encrypted by Export-Clixml - decryptable only by this Windows account on this machine),
    and records the tenant in the shared tenant index so Connect-M365TR can list/offer it.
    Multiple tenants can be configured side by side - each gets its own keyed file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ClientId,
        [Parameter(Mandatory)][string]$TenantId,
        [Parameter(Mandatory)][string]$ClientSecret,
        [Parameter(Mandatory)][string]$DisplayName,
        [Parameter(Mandatory)][string]$Organization,
        [string]$CredentialsDir = (Join-Path $PSScriptRoot '..\.credentials')
    )
    if (-not (Test-Path -LiteralPath $CredentialsDir)) { New-Item -ItemType Directory -Path $CredentialsDir -Force | Out-Null }
    $path = Join-Path $CredentialsDir "appauth_$TenantId.clixml"

    [PSCustomObject]@{
        ClientId     = $ClientId
        TenantId     = $TenantId
        ClientSecret = (ConvertTo-SecureString -String $ClientSecret -AsPlainText -Force)
    } | Export-Clixml -LiteralPath $path

    Add-M365TRStoredTenant -TenantId $TenantId -DisplayName $DisplayName -Organization $Organization -Path (Join-Path $CredentialsDir 'tenants.json')

    Write-Host "Poświadczenia aplikacji zapisane dla tenanta '$DisplayName' (zaszyfrowane DPAPI, tylko to konto/komputer): $path"
}
