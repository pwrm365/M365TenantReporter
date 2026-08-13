function Get-M365TRMobileDeviceMailboxPolicySummary {
    param($Policy)
    $parts = New-Object System.Collections.Generic.List[string]

    if ($Policy.PasswordEnabled -eq $true) {
        if ($Policy.MinPasswordLength) {
            $parts.Add("wymaga hasła (min. $($Policy.MinPasswordLength) znaków)")
        } else {
            $parts.Add('wymaga hasła')
        }
        if ($Policy.AllowSimplePassword -eq $false) { $parts.Add('proste hasło niedozwolone') }
        if ($Policy.PasswordExpiration) { $parts.Add("wygasniecie hasła: $($Policy.PasswordExpiration)") }
    }

    $encryption = if ($null -ne $Policy.RequireDeviceEncryption) { $Policy.RequireDeviceEncryption } else { $Policy.DeviceEncryptionEnabled }
    if ($encryption -eq $true) { $parts.Add('wymaga szyfrowania urządzenia') }

    if ($Policy.MaxInactivityTimeLock) {
        $ts = $Policy.MaxInactivityTimeLock -as [TimeSpan]
        if ($ts) { $parts.Add("blokada po $([int]$ts.TotalMinutes) min bezczynności") }
        else { $parts.Add("blokada po bezczynności: $($Policy.MaxInactivityTimeLock)") }
    }

    if ($Policy.AllowNonProvisionableDevices -eq $true) { $parts.Add('dopuszcza urządzenia bez obslugi zasad (non-provisionable)') }

    if ($parts.Count -eq 0) { return '(brak kluczowych ustawien do podsumowania)' }
    return ($parts -join '; ')
}

function Get-Collector_Exchange_MobileDeviceMailboxPolicies {
    param([Parameter(Mandatory)]$Context)
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
            'Co robi'  = Get-M365TRMobileDeviceMailboxPolicySummary -Policy $_
        }
    }
    New-M365TRCollectorResult -Component 'Exchange' -Section 'Zasady urządzeń mobilnych (Mobile Device Mailbox Policies)' `
        -Description 'Zasady konfiguracji urządzeń mobilnych skonfigurowane w Exchange Online.' -Status 'ok' -Data $flat
}
