function Get-Collector_Intune_SettingsCatalog {
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/deviceManagement/configurationPolicies'
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Intune' -Section 'Zasady Settings Catalog' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Intune' -Section 'Zasady Settings Catalog' -Status 'empty' `
            -Description 'Zasady oparte na Settings Catalog konfigurujące ustawienia urządzeń.'
    }
    $flat = $r.Data | ForEach-Object {
        [PSCustomObject]@{
            'Nazwa'         = $_.name
            'Platformy'     = $_.platforms
            'Technologie'   = $_.technologies
            'Zmodyfikowano' = $_.lastModifiedDateTime
        }
    }
    New-M365TRCollectorResult -Component 'Intune' -Section 'Zasady Settings Catalog' `
        -Description 'Zasady oparte na Settings Catalog konfigurujące ustawienia urządzeń.' -Status 'ok' -Data $flat
}
