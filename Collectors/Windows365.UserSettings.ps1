function Get-Collector_Windows365_UserSettings {
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/deviceManagement/virtualEndpoint/userSettings' -Beta
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Windows365' -Section 'Ustawienia użytkownika Cloud PC' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Windows365' -Section 'Ustawienia użytkownika Cloud PC' -Status 'empty' `
            -Description 'Ustawienia użytkownika Cloud PC (Windows 365) dotyczące m.in. resetu i dostępu lokalnego administratora.'
    }
    $flat = $r.Data | ForEach-Object {
        [PSCustomObject]@{
            'Nazwa'               = $_.displayName
            'DostepAdminLokalny'  = $_.localAdminEnabled
        }
    }
    New-M365TRCollectorResult -Component 'Windows365' -Section 'Ustawienia użytkownika Cloud PC' `
        -Description 'Ustawienia użytkownika Cloud PC (Windows 365) dotyczące m.in. resetu i dostępu lokalnego administratora.' -Status 'ok' -Data $flat
}
