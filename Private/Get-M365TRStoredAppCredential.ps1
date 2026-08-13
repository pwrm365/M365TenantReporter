function Get-M365TRStoredAppCredential {
    <#
    .SYNOPSIS
    Reads app-only credentials for a specific tenant, saved by Save-M365TRAppCredential.
    Returns $null (never throws) when nothing is stored for that TenantId, so Connect-M365TR
    can fall back to interactive.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$TenantId,
        [string]$CredentialsDir = (Join-Path $PSScriptRoot '..\.credentials')
    )
    $path = Join-Path $CredentialsDir "appauth_$TenantId.clixml"
    if (-not (Test-Path -LiteralPath $path)) { return $null }
    try {
        Import-Clixml -LiteralPath $path
    } catch {
        Write-Warning "Nie udało się odczytać zapisanych poświadczeń aplikacji dla tenanta ${TenantId}: $($_.Exception.Message)"
        $null
    }
}
