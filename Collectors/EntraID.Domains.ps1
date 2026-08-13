function Get-Collector_EntraID_Domains {
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/domains'
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Domeny' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Domeny' -Status 'empty' `
            -Description 'Domeny zarejestrowane i zweryfikowane w dzierzawie.'
    }
    $flat = $r.Data | ForEach-Object {
        [PSCustomObject]@{
            'Domena'              = $_.id
            'Domyślna'            = $_.isDefault
            'Zweryfikowana'       = $_.isVerified
            'TypUwierzytelniania' = $_.authenticationType
        }
    }
    New-M365TRCollectorResult -Component 'EntraID' -Section 'Domeny' `
        -Description 'Domeny zarejestrowane i zweryfikowane w dzierzawie.' -Status 'ok' -Data $flat
}
