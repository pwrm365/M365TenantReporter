function Get-M365TRCompliancePolicySummary {
    param($Policy)
    $p = $Policy
    $parts = New-Object System.Collections.Generic.List[string]

    $pwRequired = if ($null -ne $p.passwordRequired) { $p.passwordRequired } else { $p.passcodeRequired }
    if ($pwRequired -eq $true) {
        $minLen = if ($p.passwordMinimumLength) { $p.passwordMinimumLength } else { $p.passcodeMinimumLength }
        $lockMin = if ($p.passwordMinutesOfInactivityBeforeLock) { $p.passwordMinutesOfInactivityBeforeLock }
                   elseif ($p.passcodeMinutesOfInactivityBeforeLock) { $p.passcodeMinutesOfInactivityBeforeLock }
                   else { $p.passwordMinutesOfInactivityBeforeScreenTimeout }
        $txt = 'wymaga hasła/kodu'
        if ($minLen) { $txt += " (min. $minLen znaków)" }
        if ($lockMin) { $txt += "; blokada ekranu po $lockMin min bezczynności" }
        $parts.Add($txt)
    } elseif ($pwRequired -eq $false) {
        $parts.Add('nie wymaga hasła/kodu')
    }

    $encryption = if ($null -ne $p.storageRequireEncryption) { $p.storageRequireEncryption } else { $p.bitLockerEnabled }
    if ($encryption -eq $true) { $parts.Add('wymaga szyfrowania danych') }

    if ($p.securityBlockJailbrokenDevices -eq $true) { $parts.Add('blokuje urządzenia z jailbreak/root') }

    if ($p.deviceThreatProtectionEnabled -eq $true) {
        $lvl = $p.deviceThreatProtectionRequiredSecurityLevel
        $parts.Add("wymaga ochrony przed zagrożeniami (poziom: $lvl)")
    }

    if ($p.osMinimumVersion) { $parts.Add("min. wersja systemu: $($p.osMinimumVersion)") }
    if ($p.firewallEnabled -eq $true) { $parts.Add('wymaga włączonej zapory sieciowej') }
    if ($p.secureBootEnabled -eq $true) { $parts.Add('wymaga Secure Boot') }
    if ($p.requireHealthyDeviceReport -eq $true) { $parts.Add('wymaga raportu kondycji urządzenia') }

    if ($parts.Count -eq 0) { return '(brak kluczowych wymagań do podsumowania)' }
    return ($parts -join '; ')
}

function Get-Collector_Intune_CompliancePolicies {
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/deviceManagement/deviceCompliancePolicies'
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Intune' -Section 'Polityki zgodności' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Intune' -Section 'Polityki zgodności' -Status 'empty' `
            -Description 'Polityki zgodności urządzeń (Compliance Policies) wymuszane przez Intune.'
    }
    $flat = $r.Data | ForEach-Object {
        [PSCustomObject]@{
            'Nazwa'     = $_.displayName
            'Platforma' = ($_.'@odata.type' -replace '#microsoft.graph\.', '' -replace 'CompliancePolicy', '')
            'Co robi'   = Get-M365TRCompliancePolicySummary -Policy $_
        }
    }
    New-M365TRCollectorResult -Component 'Intune' -Section 'Polityki zgodności' `
        -Description 'Polityki zgodności urządzeń (Compliance Policies) wymuszane przez Intune.' -Status 'ok' -Data $flat
}
