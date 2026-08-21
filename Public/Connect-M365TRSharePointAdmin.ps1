function Connect-M365TRSharePointAdmin {
    <#
    .SYNOPSIS
    Connects to the SharePoint Online admin site app-only, via PnP.PowerShell, using the same
    certificate provisioned by Setup-AppPermissions.ps1 / Add-M365TRExchangeOnlineAccess for
    Exchange - no separate certificate or stored config needed, since PnP.PowerShell's app-only
    cert auth uses exactly the same (ClientId, Thumbprint, tenant domain) triple already saved
    for EXO. Requires the OPTIONAL "Sites.FullControl.All" SharePoint permission grant
    (Add-M365TRSharePointAdminAccess) - without it this returns $false so the pipeline can skip
    the SharePoint admin-only sections gracefully rather than abort the run.
    .PARAMETER TenantId
    Which tenant's stored EXO config to reuse. If omitted, falls back to the only configured
    tenant when exactly one exists (this function runs in an isolated, non-interactive child
    process, so it never prompts - tenant selection happens once in the parent via Connect-M365TR).
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
            Write-Warning 'Wiele skonfigurowanych tenantów, ale nie podano TenantId - sekcje administracyjne SharePoint zostaną pominięte.'
            return $false
        }
    }

    $config = if ($TenantId) { Get-M365TRStoredExoConfig -TenantId $TenantId } else { $null }
    if (-not $config) {
        Write-Warning 'Brak konfiguracji Exchange Online dla tego tenanta (uruchom Setup-AppPermissions.ps1) - sekcje administracyjne SharePoint zostaną pominięte.'
        return $false
    }

    $cert = Get-ChildItem "Cert:\CurrentUser\My\$($config.Thumbprint)" -ErrorAction SilentlyContinue
    if (-not $cert) {
        Write-Warning "Certyfikat (thumbprint: $($config.Thumbprint)) nie został znaleziony w magazynie certyfikatow tego konta - sekcje administracyjne SharePoint zostaną pominięte."
        return $false
    }

    if (-not (Get-Module -ListAvailable -Name PnP.PowerShell -ErrorAction SilentlyContinue)) {
        Write-Warning 'Modul PnP.PowerShell nie jest zainstalowany - sekcje administracyjne SharePoint zostaną pominięte.'
        return $false
    }
    Import-Module PnP.PowerShell -ErrorAction Stop

    # Adres witryny administracyjnej wynika bezpośrednio z domeny .onmicrosoft.com - Microsoft
    # nie pozwala tego dostosować niezależnie, więc nie trzeba tego wyszukiwać przez API.
    $tenantPrefix = $config.Organization -replace '\.onmicrosoft\.com$', ''
    $adminUrl = "https://$tenantPrefix-admin.sharepoint.com"

    try {
        Connect-PnPOnline -Url $adminUrl -ClientId $config.AppId -Thumbprint $config.Thumbprint -Tenant $config.Organization -ErrorAction Stop
        Write-Host 'Polaczono z witryną administracyjną SharePoint Online (PnP, app-only).'
        return $true
    } catch {
        Write-Warning "Połączenie z witryną administracyjną SharePoint Online nie powiodło się: $($_.Exception.Message)"
        return $false
    }
}
