function Get-M365TRMobileDeviceMailboxPolicySummary {
    param($Policy, [ValidateSet('pl', 'en')][string]$Language = 'pl')
    $parts = New-Object System.Collections.Generic.List[string]
    $encryption = if ($null -ne $Policy.RequireDeviceEncryption) { $Policy.RequireDeviceEncryption } else { $Policy.DeviceEncryptionEnabled }

    if ($Language -eq 'en') {
        if ($Policy.PasswordEnabled -eq $true) {
            if ($Policy.MinPasswordLength) { $parts.Add("requires a password (min. $($Policy.MinPasswordLength) characters)") }
            else { $parts.Add('requires a password') }
            if ($Policy.AllowSimplePassword -eq $false) { $parts.Add('simple password not allowed') }
            if ($Policy.PasswordExpiration) { $parts.Add("password expiration: $($Policy.PasswordExpiration)") }
        }
        if ($encryption -eq $true) { $parts.Add('requires device encryption') }
        if ($Policy.MaxInactivityTimeLock) {
            $ts = $Policy.MaxInactivityTimeLock -as [TimeSpan]
            if ($ts) { $parts.Add("locks after $([int]$ts.TotalMinutes) min of inactivity") }
            else { $parts.Add("locks after inactivity: $($Policy.MaxInactivityTimeLock)") }
        }
        if ($Policy.AllowNonProvisionableDevices -eq $true) { $parts.Add('allows devices without policy support (non-provisionable)') }
        if ($parts.Count -eq 0) { return '(no key settings to summarize)' }
    } else {
        if ($Policy.PasswordEnabled -eq $true) {
            if ($Policy.MinPasswordLength) { $parts.Add("wymaga hasła (min. $($Policy.MinPasswordLength) znaków)") }
            else { $parts.Add('wymaga hasła') }
            if ($Policy.AllowSimplePassword -eq $false) { $parts.Add('proste hasło niedozwolone') }
            if ($Policy.PasswordExpiration) { $parts.Add("wygasniecie hasła: $($Policy.PasswordExpiration)") }
        }
        if ($encryption -eq $true) { $parts.Add('wymaga szyfrowania urządzenia') }
        if ($Policy.MaxInactivityTimeLock) {
            $ts = $Policy.MaxInactivityTimeLock -as [TimeSpan]
            if ($ts) { $parts.Add("blokada po $([int]$ts.TotalMinutes) min bezczynności") }
            else { $parts.Add("blokada po bezczynności: $($Policy.MaxInactivityTimeLock)") }
        }
        if ($Policy.AllowNonProvisionableDevices -eq $true) { $parts.Add('dopuszcza urządzenia bez obslugi zasad (non-provisionable)') }
        if ($parts.Count -eq 0) { return '(brak kluczowych ustawien do podsumowania)' }
    }
    return ($parts -join '; ')
}

function Get-Collector_Exchange_MobileDeviceMailboxPolicies {
    param([Parameter(Mandatory)]$Context)
    $lang = Get-M365TRLanguage -Context $Context
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-MobileDeviceMailboxPolicy }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Zasady urządzeń mobilnych (Mobile Device Mailbox Policies)' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Zasady urządzeń mobilnych (Mobile Device Mailbox Policies)' -Status 'empty' `
            -Description 'Zasady konfiguracji urządzeń mobilnych skonfigurowane w Exchange Online.'
    }
    $flat = $r.Data | ForEach-Object {
        [PSCustomObject]@{
            'Nazwa'    = $_.Name
            'Domyślna' = $_.IsDefault
            'Co robi'  = Get-M365TRMobileDeviceMailboxPolicySummary -Policy $_ -Language $lang
        }
    }
    New-M365TRCollectorResult -Component 'Exchange' -Section 'Zasady urządzeń mobilnych (Mobile Device Mailbox Policies)' `
        -Description 'Zasady konfiguracji urządzeń mobilnych skonfigurowane w Exchange Online.' -Status 'ok' -Data $flat
}
