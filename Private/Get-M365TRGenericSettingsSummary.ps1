function Get-M365TRGenericSettingsSummary {
    <#
    .SYNOPSIS
    Best-effort fallback for policy/profile types too heterogeneous for a bespoke summary
    (e.g. Intune device configuration profiles - 100+ distinct types with wildly different
    settings). Translates the most common Intune property names into Polish "Etykieta: Wartość"
    pairs instead of a raw property=value dump; unmapped properties fall back to a humanized
    version of their camelCase name so nothing is silently hidden.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$InputObject,
        [string[]]$ExcludeProperties = @(
            'id', '@odata.type', 'displayName', 'description', 'createdDateTime',
            'lastModifiedDateTime', 'version', 'roleScopeTagIds', 'supportsScopeTags'
        ),
        [int]$MaxItems = 10
    )

    # Etykiety dla najczęstszych właściwości w profilach Intune (hasło/kod, szyfrowanie,
    # kamera/bluetooth/USB/zrzuty ekranu, Wi-Fi/VPN, praca) - reszta dostaje humanizowana nazwę.
    $labelMap = @{
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
    }
    # Wartości-enumeracje wspolne dla wielu typów profili (Windows Hello, ograniczenia PIN itp.) -
    # tłumaczone niezależnie od nazwy właściwości, żeby "disallowed"/"required" nie zostawały po angielsku.
    $enumValueMap = @{
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

    # Właściwości, dla których True/False oznacza "zablokowane/dozwolone" (nazwa zawiera Block),
    # a nie standardowe "włączone/wyłączone".
    $blockPattern = 'block|prevent|disable'
    $requirePattern = 'require|Required'
    $enablePattern = 'enable|Enabled'

    function Format-M365TRSettingValue([string]$Name, $Value) {
        if ($Value -is [bool]) {
            if ($Name -match $blockPattern) {
                $result = if ($Value) { 'Zablokowane' } else { 'Dozwolone' }
            } elseif ($Name -match $requirePattern) {
                $result = if ($Value) { 'Wymagane' } else { 'Niewymagane' }
            } elseif ($Name -match $enablePattern) {
                $result = if ($Value) { 'Włączone' } else { 'Wyłączone' }
            } else {
                $result = if ($Value) { 'Tak' } else { 'Nie' }
            }
            return $result
        }
        if ($Value -is [string] -and $enumValueMap.ContainsKey($Value.ToLowerInvariant())) {
            return $enumValueMap[$Value.ToLowerInvariant()]
        }
        # Payloady binarne/XML (np. mobileconfig zakodowany base64) potrafia miec tysiące znaków -
        # pokazujemy sam fakt ich obecności zamiast zalewać raport nieczytelnym blobem.
        if ($Value -is [string] -and $Value.Length -gt 200) {
            return "(zlozone dane konfiguracyjne - $($Value.Length) znaków, nie pokazano w całości)"
        }
        return "$Value"
    }

    $ignoredValues = @('deviceDefault', 'notConfigured', 'unavailable', 'none', '')
    $notable = $InputObject.PSObject.Properties | Where-Object {
        $_.Name -notin $ExcludeProperties -and $null -ne $_.Value -and $_.Value -isnot [array] -and
        (
            ($_.Value -is [bool]) -or
            ($_.Value -is [int] -and $_.Value -gt 0) -or
            ($_.Value -is [string] -and $_.Value -notin $ignoredValues)
        )
    }

    if (@($notable).Count -eq 0) { return '(brak skonfigurowanych ograniczeń/wymagań)' }

    $shown = $notable | Select-Object -First $MaxItems
    $pairs = $shown | ForEach-Object {
        $label = if ($labelMap.ContainsKey($_.Name)) { $labelMap[$_.Name] } else { ConvertTo-M365TRHumanizedName $_.Name }
        $value = Format-M365TRSettingValue -Name $_.Name -Value $_.Value
        "${label}: $value"
    }
    $text = $pairs -join '; '
    $remaining = @($notable).Count - $MaxItems
    if ($remaining -gt 0) { $text += " (+$remaining więcej ustawien)" }
    return $text
}
