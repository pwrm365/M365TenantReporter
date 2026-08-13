function Connect-M365TRTeams {
    <#
    .SYNOPSIS
    Connects to Microsoft Teams PowerShell (*-Cs cmdlets) app-only, using the same certificate
    provisioned for Exchange Online by Setup-AppPermissions.ps1 (Teams PowerShell app-only auth
    needs a cert + the Teams Administrator role - no separate config file needed, since the
    Exchange Online config already has everything: AppId, TenantId, CertificateThumbprint).
    Best-effort: returns $false (and warns) instead of throwing when not configured yet, so the
    main pipeline can skip Teams collectors gracefully rather than abort the run.
    .PARAMETER TenantId
    Which tenant's stored config to use. If omitted, falls back to the only configured tenant
    when exactly one exists (this function runs in an isolated, non-interactive child process).
    #>
    [CmdletBinding()]
    param(
        [string]$TenantId
    )

    if (-not $TenantId) {
        $credentialsDir = Join-Path $PSScriptRoot '..\.credentials'
        $configFiles = Get-ChildItem -Path $credentialsDir -Filter 'exoconfig_*.json' -ErrorAction SilentlyContinue
        if (@($configFiles).Count -eq 1) {
            $TenantId = ($configFiles[0].BaseName -replace '^exoconfig_', '')
        } elseif (@($configFiles).Count -gt 1) {
            Write-Warning 'Wiele skonfigurowanych tenantów, ale nie podano TenantId - sekcje Teams zostaną pominięte.'
            return $false
        }
    }

    $config = if ($TenantId) { Get-M365TRStoredExoConfig -TenantId $TenantId } else { $null }
    if (-not $config) {
        Write-Warning 'Brak konfiguracji dla tego tenanta (uruchom Setup-AppPermissions.ps1) - sekcje Teams zostaną pominięte.'
        return $false
    }

    $cert = Get-ChildItem "Cert:\CurrentUser\My\$($config.Thumbprint)" -ErrorAction SilentlyContinue
    if (-not $cert) {
        Write-Warning "Certyfikat (thumbprint: $($config.Thumbprint)) nie został znaleziony w magazynie certyfikatów tego konta - sekcje Teams zostaną pominięte."
        return $false
    }

    if (-not (Get-Module -ListAvailable -Name MicrosoftTeams -ErrorAction SilentlyContinue)) {
        Write-Warning 'Moduł MicrosoftTeams nie jest zainstalowany - sekcje Teams zostaną pominięte.'
        return $false
    }
    Import-Module MicrosoftTeams -ErrorAction Stop

    try {
        Connect-MicrosoftTeams -CertificateThumbprint $config.Thumbprint -ApplicationId $config.AppId -TenantId $TenantId -ErrorAction Stop | Out-Null
        Write-Host 'Połączono z Microsoft Teams PowerShell (app-only).'
        return $true
    } catch {
        Write-Warning "Połączenie z Microsoft Teams PowerShell nie powiodło się: $($_.Exception.Message)"
        return $false
    }
}
