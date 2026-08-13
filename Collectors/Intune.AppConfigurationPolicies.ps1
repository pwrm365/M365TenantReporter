function Get-Collector_Intune_AppConfigurationPolicies {
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/deviceAppManagement/mobileAppConfigurations'
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Intune' -Section 'Zasady konfiguracji aplikacji (App Configuration)' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Intune' -Section 'Zasady konfiguracji aplikacji (App Configuration)' -Status 'empty' `
            -Description 'Zasady konfiguracji aplikacji (App Configuration Policies) dla aplikacji mobilnych.'
    }
    $flat = $r.Data | ForEach-Object {
        [PSCustomObject]@{
            'Nazwa' = $_.displayName
            'Opis'  = $_.description
        }
    }
    New-M365TRCollectorResult -Component 'Intune' -Section 'Zasady konfiguracji aplikacji (App Configuration)' `
        -Description 'Zasady konfiguracji aplikacji (App Configuration Policies) dla aplikacji mobilnych.' -Status 'ok' -Data $flat
}
