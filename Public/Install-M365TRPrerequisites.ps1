function Install-M365TRPrerequisites {
    <#
    .SYNOPSIS
    Sprawdza, czy wszystkie moduły PowerShell wymagane przez to narzędzie (MSAL.PS,
    ExchangeOnlineManagement, MicrosoftTeams) są zainstalowane dla bieżącego użytkownika, i
    automatycznie instaluje z PowerShell Gallery te, których brakuje. Wywoływane na starcie
    każdego skryptu wejściowego (Start-Report.ps1, Setup-AppPermissions.ps1, Check-MyRoles.ps1),
    żeby na nowej maszynie pierwsze uruchomienie po prostu zadziałało, bez ręcznego
    Install-Module i bez cichego pomijania sekcji raportu z powodu brakującego modułu.
    #>
    [CmdletBinding()]
    param()

    # ExchangeOnlineManagement 3.9.x/3.10.x mają błędnie zapakowany Microsoft.Identity.Client.dll,
    # który koliduje z wersją oczekiwaną przez MSAL.PS w tym samym procesie (patrz komentarz w
    # Connect-M365TRExchange.ps1) - pinujemy jawnie znaną dobrą wersję.
    $requiredModules = @(
        @{ Name = 'MSAL.PS'; RequiredVersion = $null }
        @{ Name = 'ExchangeOnlineManagement'; RequiredVersion = '3.7.2' }
        @{ Name = 'MicrosoftTeams'; RequiredVersion = $null }
    )

    $missing = $requiredModules | Where-Object {
        $module = $_
        $installed = if ($module.RequiredVersion) {
            Get-Module -ListAvailable -Name $module.Name -ErrorAction SilentlyContinue | Where-Object Version -eq $module.RequiredVersion
        } else {
            Get-Module -ListAvailable -Name $module.Name -ErrorAction SilentlyContinue
        }
        -not $installed
    }

    if (-not $missing) {
        return
    }

    if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue | Where-Object Version -ge '2.8.5.201')) {
        Write-Host 'Instaluję dostawcę pakietów NuGet (wymagany do instalacji modułów)...'
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope CurrentUser -Force -ErrorAction Stop | Out-Null
    }
    if ((Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue).InstallationPolicy -ne 'Trusted') {
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    }

    foreach ($module in $missing) {
        $label = if ($module.RequiredVersion) { "$($module.Name) $($module.RequiredVersion)" } else { $module.Name }
        Write-Host "Moduł $label nie jest zainstalowany - instaluję dla bieżącego użytkownika..."
        $installFailed = $false
        try {
            $installArgs = @{ Name = $module.Name; Scope = 'CurrentUser'; Force = $true; AllowClobber = $true; ErrorAction = 'Stop' }
            if ($module.RequiredVersion) { $installArgs.RequiredVersion = $module.RequiredVersion }
            Install-Module @installArgs
            Write-Host "Zainstalowano moduł $label."
        } catch {
            $installFailed = $true
            Write-Warning "Nie udało się automatycznie zainstalować modułu ${label}: $($_.Exception.Message). Zainstaluj go ręcznie (Install-Module $($module.Name)$(if ($module.RequiredVersion) { " -RequiredVersion $($module.RequiredVersion)" }) -Scope CurrentUser) i uruchom ponownie."
        }

        # MSAL.PS jest jedynym modułem, bez którego dosłownie nic się nie da zrobić (logowanie do
        # Microsoft Graph) - w przeciwieństwie do ExchangeOnlineManagement/MicrosoftTeams, które
        # mają już gdzie indziej (Connect-M365TRExchange/Teams) łagodne pomijanie sekcji, jego brak
        # przerywamy jawnym błędem tutaj, zamiast pozwolić skryptowi wywalić się kilka linii dalej
        # na nieznanym poleceniu Get-MsalToken z niejasnym komunikatem.
        if ($module.Name -eq 'MSAL.PS' -and $installFailed) {
            throw "Modul MSAL.PS jest wymagany do logowania do Microsoft Graph, a automatyczna instalacja nie powiodła się. Zainstaluj recznie: Install-Module MSAL.PS -Scope CurrentUser"
        }
    }
}
