#requires -Version 7.0
<#
.SYNOPSIS
Jednorazowa konfiguracja (per tenant): tworzy dedykowana rejestracje aplikacji Azure AD z
uprawnieniami Microsoft Graph potrzebnymi do pelnej dokumentacji, nadaje zgode administratora,
konfiguruje dostęp do Exchange Online/Purview (certyfikat) i zapisuje poświadczenia lokalnie,
skojarzone z tym konkretnym tenantem. Wymaga roli Global Administrator (lub Privileged Role
Administrator + Application Administrator) na koncie, ktorym się logujesz.

Można uruchomic wielokrotnie dla różnych tenantów (np. różnych klientow) - każdy tenant
dostaje własny, oddzielny zestaw poświadczeń; Start-Report.ps1 pozwoli wybrać, do ktorego
się połączyć.
#>
[CmdletBinding()]
param(
    [string]$AppDisplayName = 'M365TenantReporter'
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'M365TenantReporter.psd1') -Force

# Klient "Microsoft Graph PowerShell" - jedyny powszechnie dostępny pierwszo-stronny klient
# Microsoftu, który deklaruje Application.ReadWrite.All / AppRoleAssignment.ReadWrite.All.
# Klient używany na co dzień do zbierania danych (Microsoft Intune PowerShell) tego NIE
# deklaruje, więc do jednorazowej konfiguracji potrzebny jest inny, szerszy klient.
$adminClientId = '14d82eec-204b-4c2f-b7e8-296a70dab67e'
$scopes = @(
    'https://graph.microsoft.com/Application.ReadWrite.All'
    'https://graph.microsoft.com/AppRoleAssignment.ReadWrite.All'
    'https://graph.microsoft.com/Directory.Read.All'
    'https://graph.microsoft.com/RoleManagement.ReadWrite.Directory'
)

Write-Host 'Logowanie administracyjne (wymagana rola Global Administrator) - zaloguj się na konto tenanta, który chcesz skonfigurować...'
$token = Get-MsalToken -ClientId $adminClientId -RedirectUri 'http://localhost' -Scopes $scopes -ForceRefresh
if (-not $token -or -not $token.AccessToken) {
    throw 'Logowanie administracyjne nie powiodło się.'
}
Write-Host "Zalogowano. Token ważny do: $($token.ExpiresOn.LocalDateTime)"

$adminContext = [PSCustomObject]@{
    ClientId  = $adminClientId
    Scopes    = $scopes
    GraphBase = 'https://graph.microsoft.com/'
    Token     = $token
}

$result = New-M365TRAppRegistration -Context $adminContext -DisplayName $AppDisplayName

Write-Host ''
if (-not $result.Success) {
    Write-Warning "Konfiguracja nie powiodla się: $($result.Message)"
    if ($result.ClientId) {
        Write-Warning "Aplikacja o ClientId $($result.ClientId) mogla zostać częściowo utworzona - sprawdź w Azure Portal > Entra ID > App registrations."
    }
    return
}

Write-Host "Aplikacja '$AppDisplayName' skonfigurowana pomyślnie w tenancie '$($result.OrganizationDisplayName)' (TenantId: $($result.TenantId))."
Write-Host "ClientId: $($result.ClientId)"
Write-Host "Nadane uprawnienia ($($result.GrantedPermissions.Count)): $($result.GrantedPermissions -join ', ')"
if ($result.FailedPermissions.Count -gt 0) {
    Write-Warning "Nie udało się nadać następujących uprawnień: $($result.FailedPermissions -join '; ')"
}

Write-Host ''
Write-Host 'Konfiguracja dostępu do Exchange Online / Purview (certyfikat, Exchange.ManageAsApp, rola Global Reader)...'
$exoResult = Add-M365TRExchangeOnlineAccess -Context $adminContext -AppId $result.ClientId -ObjectId $result.ObjectId -ServicePrincipalId $result.ServicePrincipalId
if (-not $exoResult.Success) {
    Write-Warning "Konfiguracja Exchange Online / Purview nie w pełni się powiodla: $($exoResult.Failed -join '; ')"
}

# Zapisujemy poświadczenia Graph app-only. Jeśli aplikacja już istniala (IsNewApp=false), nie
# mamy nowego sekretu do zapisania w tym przebiegu - jeśli byl już zapisany wcześniej w STARYM,
# niekluczowanym formacie (appauth.clixml/exoconfig.json sprzed wprowadzenia obslugi wielu
# tenantów), migrujemy go na nowy, kluczowany po TenantId format zamiast prosic o ponowna
# konfiguracje.
$credentialsDir = Join-Path $PSScriptRoot '.credentials'
$newAppAuthPath = Join-Path $credentialsDir "appauth_$($result.TenantId).clixml"
$oldAppAuthPath = Join-Path $credentialsDir 'appauth.clixml'
$newExoConfigPath = Join-Path $credentialsDir "exoconfig_$($result.TenantId).json"
$oldExoConfigPath = Join-Path $credentialsDir 'exoconfig.json'

if ($result.IsNewApp) {
    Save-M365TRAppCredential -ClientId $result.ClientId -TenantId $result.TenantId -ClientSecret $result.ClientSecret `
        -DisplayName $result.OrganizationDisplayName -Organization $exoResult.Organization
} elseif ((Test-Path -LiteralPath $oldAppAuthPath) -and -not (Test-Path -LiteralPath $newAppAuthPath)) {
    Write-Host 'Migruje wcześniej zapisane poświadczenia do nowego, kluczowanego po tenancie formatu...'
    Copy-Item -LiteralPath $oldAppAuthPath -Destination $newAppAuthPath -Force
    Add-M365TRStoredTenant -TenantId $result.TenantId -DisplayName $result.OrganizationDisplayName -Organization $exoResult.Organization
} elseif (-not (Test-Path -LiteralPath $newAppAuthPath)) {
    Write-Warning 'Aplikacja już istnieje, ale nie znaleziono żadnych zapisanych wcześniej poświadczeń do wykorzystania - uruchom to polecenie na koncie, które pierwotnie tworzyło aplikacje, albo usuń rejestracje aplikacji w Azure Portal i uruchom ponownie od zera.'
} else {
    Write-Host 'Aplikacja już istniala - zapisane wcześniej poświadczenia dla tego tenanta pozostają aktualne (dołożono tylko brakujące uprawnienia).'
    Add-M365TRStoredTenant -TenantId $result.TenantId -DisplayName $result.OrganizationDisplayName -Organization $exoResult.Organization
}

if ($exoResult.Thumbprint -and $exoResult.Organization) {
    Save-M365TRExoConfig -TenantId $result.TenantId -Thumbprint $exoResult.Thumbprint -AppId $exoResult.AppId -Organization $exoResult.Organization
} elseif ((Test-Path -LiteralPath $oldExoConfigPath) -and -not (Test-Path -LiteralPath $newExoConfigPath)) {
    Copy-Item -LiteralPath $oldExoConfigPath -Destination $newExoConfigPath -Force
}

Write-Host ''
Write-Host 'Konfiguracja dostępu do Microsoft Teams PowerShell (rola Teams Administrator - reużywa certyfikatu Exchange)...'
$teamsResult = Add-M365TRTeamsAccess -Context $adminContext -ServicePrincipalId $result.ServicePrincipalId
if (-not $teamsResult.Success) {
    Write-Warning "Konfiguracja Microsoft Teams nie w pełni się powiodła: $($teamsResult.Failed -join '; ')"
}

Write-Host ''
Write-Host "Tenant '$($result.OrganizationDisplayName)' gotowy. Start-Report.ps1 zaproponuje go teraz do wyboru przy logowaniu."
