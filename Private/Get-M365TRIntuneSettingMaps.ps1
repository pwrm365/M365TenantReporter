function Get-M365TRIntuneLabelMap {
    <#
    .SYNOPSIS
    Shared curated Polish labels for the most common Intune policy/profile property names
    (password/passcode, encryption, camera/bluetooth/USB/screen capture, Wi-Fi/VPN, work
    profile). Used both by the one-line "Co robi" summary (Get-M365TRGenericSettingsSummary)
    and by the full per-object "Ustawienia" detail tables, so the two stay consistent instead of
    drifting into two separate label sets.
    #>
    return @{
        passwordRequired                              = 'Wymagane hasło/kod'
        passcodeRequired                               = 'Wymagany kod dostępu'
        passwordMinimumLength                          = 'Minimalna długość hasła'
        passcodeMinimumLength                          = 'Minimalna długość kodu'
        passwordBlockSimple                            = 'Proste hasło'
        passcodeBlockSimple                            = 'Prosty kod'
        passwordRequiredType                           = 'Wymagany typ hasła'
        passcodeRequiredType                           = 'Wymagany typ kodu'
        passwordMinutesOfInactivityBeforeLock          = 'Blokada ekranu po (min. bezczynności)'
        passcodeMinutesOfInactivityBeforeLock          = 'Blokada ekranu po (min. bezczynności)'
        passwordMinutesOfInactivityBeforeScreenTimeout = 'Wygaszenie ekranu po (min.)'
        passcodeMinutesOfInactivityBeforeScreenTimeout = 'Wygaszenie ekranu po (min.)'
        passwordExpirationDays                         = 'Ważność hasła (dni)'
        passwordPreviousPasswordBlockCount             = 'Blokada powtórzenia ostatnich haseł (liczba)'
        passwordSignInFailureCountBeforeFactoryReset   = 'Reset urządzenia po nieudanych próbach (liczba)'
        storageRequireEncryption                       = 'Szyfrowanie danych'
        bitLockerEnabled                               = 'Szyfrowanie BitLocker'
        requireDeviceEncryption                        = 'Wymagane szyfrowanie urządzenia'
        securityBlockJailbrokenDevices                 = 'Urządzenia z jailbreak/root'
        deviceThreatProtectionEnabled                  = 'Ochrona przed zagrożeniami'
        deviceThreatProtectionRequiredSecurityLevel    = 'Wymagany poziom ochrony'
        osMinimumVersion                               = 'Minimalna wersja systemu'
        osMaximumVersion                               = 'Maksymalna wersja systemu'
        secureBootEnabled                              = 'Secure Boot'
        codeIntegrityEnabled                            = 'Integralność kodu'
        firewallEnabled                                 = 'Zapora sieciowa'
        firewallBlockAllIncoming                        = 'Blokada połączeń przychodzących (zapora)'
        firewallEnableStealthMode                       = 'Tryb ukryty zapory'
        cameraBlocked                                   = 'Kamera'
        blockCamera                                     = 'Kamera'
        bluetoothBlocked                                = 'Bluetooth'
        wifiBlocked                                     = 'Wi-Fi'
        screenCaptureBlocked                            = 'Zrzuty ekranu'
        workProfileBlockScreenCapture                   = 'Zrzuty ekranu w profilu służbowym'
        workProfileBlockCamera                          = 'Kamera w profilu służbowym'
        workProfileBlockNotificationsWhileDeviceLocked  = 'Powiadomienia przy zablokowanym ekranie'
        workProfileBlockAddingAccounts                  = 'Dodawanie kont w profilu służbowym'
        workProfileBluetoothEnableContactSharing        = 'Udostępnianie kontaktów przez Bluetooth'
        workProfileBlockCrossProfileCallerId            = 'ID dzwoniącego między profilami'
        workProfileBlockCrossProfileContactsSearch      = 'Wyszukiwanie kontaktów między profilami'
        workProfileBlockCrossProfileCopyPaste           = 'Kopiuj-wklej między profilami'
        workProfileDataSharingType                      = 'Udostępnianie danych między profilami'
        workProfileDefaultAppPermissionPolicy           = 'Domyślne uprawnienia aplikacji'
        requireHealthyDeviceReport                      = 'Wymagany raport kondycji urządzenia'
        managedEmailProfileRequired                     = 'Wymagany zarządzany profil poczty'
        securityDisableUsbDebugging                     = 'Debugowanie USB'
        securityPreventInstallAppsFromUnknownSources    = 'Instalacja aplikacji spoza sklepu'
        securityRequireVerifyApps                       = 'Weryfikacja aplikacji (Google Play Protect)'
        securityRequireGooglePlayServices               = 'Wymagane Google Play Services'
        securityRequireUpToDateSecurityProviders        = 'Aktualne dostawcy zabezpieczeń'
        securityRequireCompanyPortalAppIntegrity        = 'Integralność aplikacji Company Portal'
        lockScreenBlockControlCenter                    = 'Centrum sterowania na ekranie blokady'
        lockScreenBlockNotificationView                 = 'Podgląd powiadomień na ekranie blokady'
        lockScreenBlockTodayView                        = 'Widok "Dziś" na ekranie blokady'
        mediaContentRatingApps                          = 'Ograniczenia wiekowe aplikacji'
        state                                            = 'Stan'
        securityDeviceRequired                          = 'Wymagany zabezpieczający moduł sprzętowy (TPM)'
        unlockWithBiometricsEnabled                     = 'Odblokowanie biometryczne'
        remotePassportEnabled                           = 'Remote Passport (logowanie z innego urządzenia)'
        pinUppercaseCharactersUsage                     = 'Wielkie litery w kodzie PIN'
        pinLowercaseCharactersUsage                     = 'Małe litery w kodzie PIN'
        pinSpecialCharactersUsage                       = 'Znaki specjalne w kodzie PIN'
        pinMinimumLength                                = 'Minimalna długość kodu PIN'
        pinMaximumLength                                = 'Maksymalna długość kodu PIN'
        pinExpirationInDays                             = 'Ważność kodu PIN (dni)'
        pinPreviousBlockCount                           = 'Blokada powtórzenia ostatnich kodów PIN (liczba)'
        enhancedBiometricsState                          = 'Rozszerzona biometria (Windows Hello)'
        allowNonBlockingAppInstallation                 = 'Instalacja aplikacji w tle podczas OOBE'
        passwordRequiredToUnlockFromIdle                = 'Wymagane hasło po powrocie z bezczynności'
        earlyLaunchAntiMalwareDriverEnabled              = 'Wczesne uruchamianie sterownika antymalware (ELAM)'
        isFeatured                                       = 'Polecana aplikacja'
        publishingState                                  = 'Stan publikacji'
        committedContentVersion                          = 'Wersja zawartości'
        fileName                                         = 'Nazwa pliku instalacyjnego'
        setupFilePath                                    = 'Ścieżka pliku instalacyjnego'
        minimumSupportedWindowsRelease                  = 'Minimalna wersja Windows'
    }
}

function Get-M365TRIntuneEnumValueMap {
    <#
    .SYNOPSIS
    Value-enumerations shared across many Intune profile types (Windows Hello, PIN
    restrictions, etc.) - translated independently of the property name so
    "disallowed"/"required" never leak through untranslated regardless of which property held it.
    #>
    return @{
        disallowed    = 'Niedozwolone'
        notallowed    = 'Niedozwolone'
        allowed       = 'Dozwolone'
        required      = 'Wymagane'
        blocked       = 'Zablokowane'
        alphanumeric  = 'Alfanumeryczny'
        numeric       = 'Numeryczny'
        lowsecurity   = 'Niski poziom zabezpieczeń'
        enabled       = 'Włączone'
        disabled      = 'Wyłączone'
        notconfigured = 'Nieskonfigurowane'
    }
}

function Format-M365TRIntuneSettingValue {
    <#
    .SYNOPSIS
    Context-aware value formatter shared by the one-line summary and the full detail tables:
    a bare `$true`/`$false` reads very differently depending on whether the property name says
    "block" (Zablokowane/Dozwolone), "require" (Wymagane/Niewymagane), "enable" (Włączone/
    Wyłączone), or none of those (plain Tak/Nie).
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Name, $Value)

    $blockPattern = 'block|prevent|disable'
    $requirePattern = 'require|Required'
    $enablePattern = 'enable|Enabled'
    $enumValueMap = Get-M365TRIntuneEnumValueMap

    if ($Value -is [bool]) {
        if ($Name -match $blockPattern) { return $(if ($Value) { 'Zablokowane' } else { 'Dozwolone' }) }
        if ($Name -match $requirePattern) { return $(if ($Value) { 'Wymagane' } else { 'Niewymagane' }) }
        if ($Name -match $enablePattern) { return $(if ($Value) { 'Włączone' } else { 'Wyłączone' }) }
        return $(if ($Value) { 'Tak' } else { 'Nie' })
    }
    if ($Value -is [string] -and $enumValueMap.ContainsKey($Value.ToLowerInvariant())) {
        return $enumValueMap[$Value.ToLowerInvariant()]
    }
    # Binary/XML payloads (e.g. base64-encoded mobileconfig) can run thousands of characters -
    # note their presence instead of flooding the report with an unreadable blob.
    if ($Value -is [string] -and $Value.Length -gt 200) {
        return "(zlozone dane konfiguracyjne - $($Value.Length) znaków, nie pokazano w całości)"
    }
    return "$Value"
}
