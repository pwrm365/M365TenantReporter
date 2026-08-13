function Get-Collector_Intune_DeviceConfigurations {
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/deviceManagement/deviceConfigurations'
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Intune' -Section 'Profile konfiguracyjne urządzeń' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Intune' -Section 'Profile konfiguracyjne urządzeń' -Status 'empty' `
            -Description 'Profile konfiguracyjne urządzeń (Device Configuration Profiles) zarzadzane przez Intune.'
    }
    $flat = $r.Data | ForEach-Object {
        [PSCustomObject]@{
            'Nazwa'   = $_.displayName
            'Typ'     = ConvertTo-M365TRFriendlyConfigTypeName ($_.'@odata.type' -replace '#microsoft.graph\.', '')
            'Co robi' = Get-M365TRGenericSettingsSummary -InputObject $_
        }
    }
    New-M365TRCollectorResult -Component 'Intune' -Section 'Profile konfiguracyjne urządzeń' `
        -Description 'Profile konfiguracyjne urządzeń (Device Configuration Profiles) zarzadzane przez Intune.' -Status 'ok' -Data $flat
}
