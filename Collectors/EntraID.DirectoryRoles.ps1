function Get-Collector_EntraID_DirectoryRoles {
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/directoryRoles'
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Role katalogowe' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Role katalogowe' -Status 'empty' `
            -Description 'Role katalogowe aktywne w dzierzawie Entra ID.'
    }
    $flat = $r.Data | ForEach-Object {
        [PSCustomObject]@{
            'Nazwa'       = $_.displayName
            'Opis'        = $_.description
            'SzablonRoli' = $_.roleTemplateId
        }
    }
    New-M365TRCollectorResult -Component 'EntraID' -Section 'Role katalogowe' `
        -Description 'Role katalogowe aktywne w dzierzawie Entra ID.' -Status 'ok' -Data $flat
}
