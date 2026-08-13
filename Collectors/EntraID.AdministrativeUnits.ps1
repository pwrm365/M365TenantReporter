function Get-Collector_EntraID_AdministrativeUnits {
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/directory/administrativeUnits'
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Jednostki administracyjne' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Jednostki administracyjne' -Status 'empty' `
            -Description 'Jednostki administracyjne używane do delegowania administracji w Entra ID.'
    }
    $flat = $r.Data | ForEach-Object {
        [PSCustomObject]@{
            'Nazwa'      = $_.displayName
            'Opis'       = $_.description
            'Widoczność' = $_.visibility
        }
    }
    New-M365TRCollectorResult -Component 'EntraID' -Section 'Jednostki administracyjne' `
        -Description 'Jednostki administracyjne używane do delegowania administracji w Entra ID.' -Status 'ok' -Data $flat
}
