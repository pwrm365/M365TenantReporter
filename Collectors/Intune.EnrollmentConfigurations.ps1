function Get-Collector_Intune_EnrollmentConfigurations {
    param([Parameter(Mandatory)]$Context)
    $lang = Get-M365TRLanguage -Context $Context
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/deviceManagement/deviceEnrollmentConfigurations'
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Intune' -Section 'Konfiguracje rejestracji urządzeń' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Intune' -Section 'Konfiguracje rejestracji urządzeń' -Status 'empty' `
            -Description 'Konfiguracje rejestracji urządzeń (Device Enrollment Configurations) w Intune.'
    }
    $flat = $r.Data | ForEach-Object {
        [PSCustomObject]@{
            'Nazwa'     = $_.displayName
            'Typ'       = ConvertTo-M365TRFriendlyConfigTypeName ($_.'@odata.type' -replace '#microsoft.graph\.', '')
            'Priorytet' = $_.priority
            'Co robi'   = Get-M365TRGenericSettingsSummary -InputObject $_ -Language $lang -ExcludeProperties @('id', '@odata.type', 'displayName', 'description', 'createdDateTime', 'lastModifiedDateTime', 'version', 'roleScopeTagIds', 'priority')
        }
    }
    New-M365TRCollectorResult -Component 'Intune' -Section 'Konfiguracje rejestracji urządzeń' `
        -Description 'Konfiguracje rejestracji urządzeń (Device Enrollment Configurations) w Intune.' -Status 'ok' -Data $flat
}
