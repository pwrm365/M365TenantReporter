function Get-Collector_EntraID_AuthenticationMethodsPolicy {
    param([Parameter(Mandatory)]$Context)
    $lang = Get-M365TRLanguage -Context $Context
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/policies/authenticationMethodsPolicy'
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Polityka metod uwierzytelniania' -Status $r.Status -Message $r.Message
    }
    $pol = $r.Data | Select-Object -First 1
    if (-not $pol -or @($pol.authenticationMethodConfigurations).Count -eq 0) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Polityka metod uwierzytelniania' -Status 'empty' `
            -Description 'Konfiguracja polityki metod uwierzytelniania (MFA) w Entra ID.'
    }

    $methodNames = @{
        Fido2                 = 'Klucz bezpieczeństwa (FIDO2)'
        MicrosoftAuthenticator = 'Aplikacja Microsoft Authenticator'
        Sms                   = 'SMS'
        TemporaryAccessPass   = 'Tymczasowy kod dostępu (TAP)'
        SoftwareOath          = 'Aplikacja uwierzytelniająca (Software OATH)'
        HardwareOath          = 'Sprzetowy token OATH'
        Voice                 = 'Połączenie głosowe'
        Email                 = 'E-mail (odzyskiwanie hasła)'
        X509Certificate       = 'Certyfikat X.509'
        Certificate           = 'Certyfikat X.509'
        VerifiableCredentials = 'Verified ID (poświadczenia weryfikowalne)'
        QRCodePin             = 'Kod QR + PIN'
    }
    $stateNames = @{ enabled = 'Włączona'; disabled = 'Wyłączona' }

    $rows = foreach ($m in ($pol.authenticationMethodConfigurations | Sort-Object id)) {
        [PSCustomObject]@{
            'Metoda uwierzytelniania' = if ($methodNames.ContainsKey($m.id)) { $methodNames[$m.id] } else { $m.id }
            'Status'                  = if ($stateNames.ContainsKey($m.state)) { $stateNames[$m.state] } else { $m.state }
        }
    }
    $rows = @($rows)

    $desc = if ($lang -eq 'en') {
        $modified = if ($pol.lastModifiedDateTime) { ([datetime]$pol.lastModifiedDateTime).ToString('MM/dd/yyyy HH:mm') } else { 'unknown' }
        "Sign-in methods allowed in the tenant and their state. Policy last modified: $modified."
    } else {
        $modified = if ($pol.lastModifiedDateTime) { ([datetime]$pol.lastModifiedDateTime).ToString('dd.MM.yyyy HH:mm') } else { 'nieznana' }
        "Metody logowania dopuszczone w tenancie oraz ich stan. Ostatnia modyfikacja polityki: $modified."
    }
    New-M365TRCollectorResult -Component 'EntraID' -Section 'Polityka metod uwierzytelniania' `
        -Description $desc `
        -Status 'ok' -Data $rows
}
