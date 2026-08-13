function Get-Collector_Intune_AppProtectionPolicies {
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/deviceAppManagement/managedAppPolicies'
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Intune' -Section 'Zasady ochrony aplikacji (App Protection)' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Intune' -Section 'Zasady ochrony aplikacji (App Protection)' -Status 'empty' `
            -Description 'Zasady ochrony aplikacji (App Protection Policies) dla aplikacji zarzadzanych.'
    }
    $flat = $r.Data | ForEach-Object {
        [PSCustomObject]@{
            'Nazwa' = $_.displayName
            'Typ'   = ($_.'@odata.type' -replace '#microsoft.graph\.', '')
        }
    }
    New-M365TRCollectorResult -Component 'Intune' -Section 'Zasady ochrony aplikacji (App Protection)' `
        -Description 'Zasady ochrony aplikacji (App Protection Policies) dla aplikacji zarzadzanych.' -Status 'ok' -Data $flat
}
