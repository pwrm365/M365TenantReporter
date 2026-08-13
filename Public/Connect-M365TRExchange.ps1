function Connect-M365TRExchange {
    <#
    .SYNOPSIS
    Connects to Exchange Online and Security & Compliance (Purview) PowerShell app-only, using
    the certificate provisioned by Setup-AppPermissions.ps1 / Add-M365TRExchangeOnlineAccess for
    the given tenant. Best-effort: returns $false (and warns) instead of throwing when not
    configured yet, so the main pipeline can skip Exchange/Purview collectors gracefully rather
    than abort the run.
    .PARAMETER TenantId
    Which tenant's stored EXO config to use. If omitted, falls back to the only configured
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
            Write-Warning 'Wiele skonfigurowanych tenantów Exchange Online, ale nie podano TenantId - sekcje Exchange/Purview zostaną pominięte.'
            return $false
        }
    }

    $config = if ($TenantId) { Get-M365TRStoredExoConfig -TenantId $TenantId } else { $null }
    if (-not $config) {
        Write-Warning 'Brak konfiguracji Exchange Online dla tego tenanta (uruchom Setup-AppPermissions.ps1) - sekcje Exchange/Purview zostaną pominięte.'
        return $false
    }

    $cert = Get-ChildItem "Cert:\CurrentUser\My\$($config.Thumbprint)" -ErrorAction SilentlyContinue
    if (-not $cert) {
        Write-Warning "Certyfikat (thumbprint: $($config.Thumbprint)) nie został znaleziony w magazynie certyfikatow tego konta - sekcje Exchange/Purview zostaną pominięte."
        return $false
    }

    # Uwaga: ExchangeOnlineManagement 3.9.x/3.10.x mają bledny pakiet - Microsoft.Identity.Client.dll
    # w folderze netCore nie zgadza się z wersja, jakiej oczekuje reszta modułu (FileLoadException
    # "manifest definition does not match the assembly reference"). Wersja 3.7.2 dziala poprawnie -
    # przypinamy ja jawnie, dopoki Microsoft nie naprawi nowszych wydan.
    $exoModuleVersion = '3.7.2'
    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement -ErrorAction SilentlyContinue | Where-Object Version -eq $exoModuleVersion)) {
        Write-Warning "Modul ExchangeOnlineManagement w wersji $exoModuleVersion nie jest zainstalowany - sekcje Exchange/Purview zostaną pominięte."
        return $false
    }
    Import-Module ExchangeOnlineManagement -RequiredVersion $exoModuleVersion -ErrorAction Stop

    $exoOk = $false
    $ippsOk = $false
    try {
        Connect-ExchangeOnline -CertificateThumbprint $config.Thumbprint -AppId $config.AppId -Organization $config.Organization -ShowBanner:$false -ErrorAction Stop
        $exoOk = $true
        Write-Host 'Polaczono z Exchange Online (app-only).'
    } catch {
        Write-Warning "Połączenie z Exchange Online nie powiodło się: $($_.Exception.Message)"
    }
    try {
        Connect-IPPSSession -CertificateThumbprint $config.Thumbprint -AppId $config.AppId -Organization $config.Organization -ErrorAction Stop
        $ippsOk = $true
        Write-Host 'Polaczono z Security & Compliance (Purview) PowerShell (app-only).'
    } catch {
        Write-Warning "Połączenie z Security & Compliance PowerShell nie powiodło się: $($_.Exception.Message)"
    }

    return ($exoOk -or $ippsOk)
}
