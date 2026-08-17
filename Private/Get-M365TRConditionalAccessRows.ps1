function Get-M365TRCaEnumMap {
    <#
    .SYNOPSIS
    Polish labels for the small, fixed Conditional Access condition enumerations (client app
    types, device platforms, risk levels, user actions) - translated independently of which
    condition they appear under, since the same raw Graph values recur across all of them.
    #>
    return @{
        all                                    = 'Wszystkie'
        none                                   = 'Brak'
        browser                                = 'Przeglądarka'
        mobileAppsAndDesktopClients            = 'Aplikacje mobilne i klienty desktopowe'
        exchangeActiveSync                     = 'Exchange ActiveSync'
        easSupported                           = 'Exchange ActiveSync (obsługiwane)'
        other                                  = 'Inne klienty'
        android                                = 'Android'
        iOS                                    = 'iOS'
        windows                                = 'Windows'
        windowsPhone                           = 'Windows Phone'
        macOS                                  = 'macOS'
        linux                                  = 'Linux'
        low                                    = 'Niski'
        medium                                 = 'Średni'
        high                                   = 'Wysoki'
        hidden                                 = 'Ukryty'
        unknownFutureValue                     = '(nieznana przyszła wartość)'
        registerSecurityInformation            = 'Rejestracja informacji zabezpieczających'
        registerOrJoinDevices                  = 'Rejestracja/przyłączanie urządzeń'
        urnUserActionrestrictedaccess          = 'Ograniczony dostęp (Privileged Identity Management)'
        mfa                                    = 'Uwierzytelnianie wieloskładnikowe (MFA)'
        compliantDevice                        = 'Urządzenie zgodne'
        domainJoinedDevice                     = 'Urządzenie przyłączone do domeny (hybrydowe)'
        approvedApplication                    = 'Zatwierdzona aplikacja kliencka'
        compliantApplication                   = 'Zgodna aplikacja (App Protection)'
        passwordChange                         = 'Wymagana zmiana hasła'
        block                                  = 'Blokada dostępu'
        GuestsOrExternalUsers                  = 'Goście/użytkownicy zewnętrzni'
    }
}

function Format-M365TRIdArray {
    <#
    .SYNOPSIS
    Joins a Conditional Access condition array (user/group/role GUIDs, or plain values like
    "All"/"None") into one display string. When $Resolver is given, each GUID-looking entry is
    resolved through it (used for groups); role template IDs and user IDs are shown as-is, same
    as how the reference Intune documentation style leaves them unresolved. Known small
    enumerations (client app types, platforms, risk levels, ...) are translated to Polish via
    Get-M365TRCaEnumMap; anything else (GUIDs, resolved names) passes through unchanged.
    #>
    [CmdletBinding()]
    param([object[]]$Values, [scriptblock]$Resolver, [switch]$TranslateEnum)

    $items = @($Values) | Where-Object { $_ }
    if ($items.Count -eq 0) { return $null }
    if ($Resolver) { $items = $items | ForEach-Object { & $Resolver $_ } }
    if ($TranslateEnum) {
        $map = Get-M365TRCaEnumMap
        $items = $items | ForEach-Object { if ($map.ContainsKey($_)) { $map[$_] } else { $_ } }
    }
    return ($items -join ', ')
}

function Get-M365TRConditionalAccessRows {
    <#
    .SYNOPSIS
    Flattens one Conditional Access policy's conditions/grantControls/sessionControls into
    "Ustawienie / Wartość" rows, resolving group IDs to display names (role template IDs and user
    IDs are left as GUIDs - Conditional Access has no cheap way to resolve a role template ID to
    its role name without a second lookup table, and per-user resolution doesn't scale to policies
    that list dozens of users).
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Context, [Parameter(Mandatory)]$Policy)

    $rows = New-Object System.Collections.Generic.List[object]
    function Add-Row([string]$Label, $Value) {
        if ($null -eq $Value -or "$Value" -eq '') { return }
        $rows.Add([PSCustomObject]@{ Ustawienie = $Label; Wartość = "$Value" })
    }

    $groupResolver = { param($id) Resolve-M365TRGroupName -Context $Context -GroupId $id }
    $c = $Policy.conditions

    # ---- Users and groups ----
    $u = $c.users
    if ($u) {
        Add-Row 'Użytkownicy i grupy - dołącz: użytkownicy' (Format-M365TRIdArray -Values $u.includeUsers -TranslateEnum)
        Add-Row 'Użytkownicy i grupy - dołącz: grupy' (Format-M365TRIdArray -Values $u.includeGroups -Resolver $groupResolver)
        Add-Row 'Użytkownicy i grupy - dołącz: role katalogowe' (Format-M365TRIdArray -Values $u.includeRoles)
        if ($u.includeGuestsOrExternalUsers -and $u.includeGuestsOrExternalUsers.guestOrExternalUserTypes) {
            Add-Row 'Użytkownicy i grupy - dołącz: goście/zewnętrzni' $u.includeGuestsOrExternalUsers.guestOrExternalUserTypes
        }
        Add-Row 'Użytkownicy i grupy - wyklucz: użytkownicy' (Format-M365TRIdArray -Values $u.excludeUsers -TranslateEnum)
        Add-Row 'Użytkownicy i grupy - wyklucz: grupy' (Format-M365TRIdArray -Values $u.excludeGroups -Resolver $groupResolver)
        Add-Row 'Użytkownicy i grupy - wyklucz: role katalogowe' (Format-M365TRIdArray -Values $u.excludeRoles)
        if ($u.excludeGuestsOrExternalUsers -and $u.excludeGuestsOrExternalUsers.guestOrExternalUserTypes) {
            Add-Row 'Użytkownicy i grupy - wyklucz: goście/zewnętrzni' $u.excludeGuestsOrExternalUsers.guestOrExternalUserTypes
        }
    }

    # ---- Cloud apps / actions ----
    $a = $c.applications
    if ($a) {
        Add-Row 'Aplikacje w chmurze - dołącz' (Format-M365TRIdArray -Values $a.includeApplications -TranslateEnum)
        Add-Row 'Aplikacje w chmurze - wyklucz' (Format-M365TRIdArray -Values $a.excludeApplications -TranslateEnum)
        Add-Row 'Akcje użytkownika' (Format-M365TRIdArray -Values $a.includeUserActions -TranslateEnum)
        Add-Row 'Konteksty uwierzytelniania' (Format-M365TRIdArray -Values $a.includeAuthenticationContextClassReferences)
    }

    # ---- Platforms / locations / client apps / risk ----
    if ($c.platforms) {
        Add-Row 'Platformy urządzeń - dołącz' (Format-M365TRIdArray -Values $c.platforms.includePlatforms -TranslateEnum)
        Add-Row 'Platformy urządzeń - wyklucz' (Format-M365TRIdArray -Values $c.platforms.excludePlatforms -TranslateEnum)
    }
    if ($c.locations) {
        Add-Row 'Lokalizacje - dołącz' (Format-M365TRIdArray -Values $c.locations.includeLocations -TranslateEnum)
        Add-Row 'Lokalizacje - wyklucz' (Format-M365TRIdArray -Values $c.locations.excludeLocations -TranslateEnum)
    }
    Add-Row 'Typy aplikacji klienckich' (Format-M365TRIdArray -Values $c.clientAppTypes -TranslateEnum)
    Add-Row 'Poziom ryzyka logowania' (Format-M365TRIdArray -Values $c.signInRiskLevels -TranslateEnum)
    Add-Row 'Poziom ryzyka użytkownika' (Format-M365TRIdArray -Values $c.userRiskLevels -TranslateEnum)
    if ($c.devices -and $c.devices.deviceFilter -and $c.devices.deviceFilter.rule) {
        Add-Row 'Filtr urządzeń' "$($c.devices.deviceFilter.mode): $($c.devices.deviceFilter.rule)"
    }

    # ---- Grant controls ----
    $g = $Policy.grantControls
    if ($g) {
        if (@($g.builtInControls) -contains 'block') {
            Add-Row 'Kontrola dostępu' 'Blokuj dostęp'
        } elseif ($g.builtInControls -or $g.authenticationStrength) {
            $op = if ($g.operator -eq 'OR') { 'dowolne z poniższych' } else { 'wszystkie z poniższych' }
            $controls = Format-M365TRIdArray -Values $g.builtInControls -TranslateEnum
            $value = if ($controls) { "Przyznaj dostęp - wymagaj ($op): $controls" } else { 'Przyznaj dostęp' }
            Add-Row 'Kontrola dostępu' $value
        }
        if ($g.authenticationStrength -and $g.authenticationStrength.displayName) {
            Add-Row 'Wymagana siła uwierzytelniania' $g.authenticationStrength.displayName
        }
        Add-Row 'Wymagane warunki korzystania' (Format-M365TRIdArray -Values $g.termsOfUse)
    }

    # ---- Session controls ----
    $s = $Policy.sessionControls
    if ($s) {
        if ($s.signInFrequency -and $s.signInFrequency.isEnabled) {
            Add-Row 'Sesja - częstotliwość logowania' "co $($s.signInFrequency.value) $($s.signInFrequency.type) ($($s.signInFrequency.frequencyInterval))"
        }
        if ($s.persistentBrowser -and $s.persistentBrowser.isEnabled) {
            Add-Row 'Sesja - trwałość przeglądarki' $s.persistentBrowser.mode
        }
        if ($s.applicationEnforcedRestrictions -and $s.applicationEnforcedRestrictions.isEnabled) {
            Add-Row 'Sesja - ograniczenia wymuszane przez aplikację' 'Włączone'
        }
        if ($s.cloudAppSecurity -and $s.cloudAppSecurity.isEnabled) {
            Add-Row 'Sesja - Cloud App Security' $s.cloudAppSecurity.cloudAppSecurityType
        }
        if ($s.continuousAccessEvaluation -and $s.continuousAccessEvaluation.mode) {
            Add-Row 'Sesja - ciągła ocena dostępu' $s.continuousAccessEvaluation.mode
        }
        if ($s.disableResilienceDefaults -eq $true) {
            Add-Row 'Sesja - domyślna odporność na awarie' 'Wyłączona'
        }
    }

    return $rows
}
