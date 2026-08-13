function Get-Collector_Intune_MobileApps {
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/deviceAppManagement/mobileApps'
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Intune' -Section 'Aplikacje mobilne' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Intune' -Section 'Aplikacje mobilne' -Status 'empty' `
            -Description 'Aplikacje mobilne opublikowane w Intune (Mobile Apps).'
    }
    $flat = $r.Data | ForEach-Object {
        [PSCustomObject]@{
            'Nazwa'    = $_.displayName
            'Typ'      = ($_.'@odata.type' -replace '#microsoft.graph\.', '')
            'Wydawca'  = $_.publisher
        }
    }
    New-M365TRCollectorResult -Component 'Intune' -Section 'Aplikacje mobilne' `
        -Description 'Aplikacje mobilne opublikowane w Intune (Mobile Apps).' -Status 'ok' -Data $flat
}
