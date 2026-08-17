function Get-M365TRAutopilotProfileSummary {
    param($Profile, [ValidateSet('pl', 'en')][string]$Language = 'pl')
    $parts = New-Object System.Collections.Generic.List[string]
    $oobe = $Profile.outOfBoxExperienceSettings

    if ($Language -eq 'en') {
        if ($oobe) {
            if ($oobe.userType) { $parts.Add("user type: $($oobe.userType)") }
            if ($oobe.deviceUsageType) { $parts.Add("usage: $($oobe.deviceUsageType)") }
            if ($oobe.hidePrivacySettings -eq $true) { $parts.Add('hides privacy settings') }
            if ($oobe.hideEULA -eq $true) { $parts.Add('hides the EULA') }
            if ($oobe.hideEscapeLink -eq $true) { $parts.Add('blocks skipping OOBE (no "escape link")') }
            if ($oobe.skipKeyboardSelectionPage -eq $true) { $parts.Add('skips keyboard selection') }
        }
        if ($Profile.deviceNameTemplate) { $parts.Add("device name template: $($Profile.deviceNameTemplate)") }
        if ($parts.Count -eq 0) { return '(no key settings to summarize)' }
    } else {
        if ($oobe) {
            if ($oobe.userType) { $parts.Add("typ użytkownika: $($oobe.userType)") }
            if ($oobe.deviceUsageType) { $parts.Add("użycie: $($oobe.deviceUsageType)") }
            if ($oobe.hidePrivacySettings -eq $true) { $parts.Add('ukrywa ustawienia prywatności') }
            if ($oobe.hideEULA -eq $true) { $parts.Add('ukrywa umowe licencyjna (EULA)') }
            if ($oobe.hideEscapeLink -eq $true) { $parts.Add('blokuje pominiecie OOBE (brak "escape link")') }
            if ($oobe.skipKeyboardSelectionPage -eq $true) { $parts.Add('pomija wybór klawiatury') }
        }
        if ($Profile.deviceNameTemplate) { $parts.Add("szablon nazwy urządzenia: $($Profile.deviceNameTemplate)") }
        if ($parts.Count -eq 0) { return '(brak kluczowych ustawien do podsumowania)' }
    }
    return ($parts -join '; ')
}

function Get-Collector_Intune_AutopilotProfiles {
    param([Parameter(Mandatory)]$Context)
    $lang = Get-M365TRLanguage -Context $Context
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/deviceManagement/windowsAutopilotDeploymentProfiles'
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Intune' -Section 'Profile Windows Autopilot' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Intune' -Section 'Profile Windows Autopilot' -Status 'empty' `
            -Description 'Profile wdrożenia Windows Autopilot używane przy rejestracji nowych urządzeń.'
    }
    $flat = $r.Data | ForEach-Object {
        [PSCustomObject]@{
            'Nazwa'   = $_.displayName
            'Co robi' = Get-M365TRAutopilotProfileSummary -Profile $_ -Language $lang
        }
    }
    New-M365TRCollectorResult -Component 'Intune' -Section 'Profile Windows Autopilot' `
        -Description 'Profile wdrożenia Windows Autopilot używane przy rejestracji nowych urządzeń.' -Status 'ok' -Data $flat
}
