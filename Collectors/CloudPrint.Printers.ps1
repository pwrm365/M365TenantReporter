function Get-Collector_CloudPrint_Printers {
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/print/printers'
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'CloudPrint' -Section 'Drukarki (Universal Print)' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'CloudPrint' -Section 'Drukarki (Universal Print)' -Status 'empty' `
            -Description 'Drukarki zarejestrowane w usludze Universal Print.'
    }
    $flat = $r.Data | ForEach-Object {
        [PSCustomObject]@{
            'Nazwa'     = $_.displayName
            'Producent' = $_.manufacturer
            'Model'     = $_.model
        }
    }
    New-M365TRCollectorResult -Component 'CloudPrint' -Section 'Drukarki (Universal Print)' `
        -Description 'Drukarki zarejestrowane w usludze Universal Print.' -Status 'ok' -Data $flat
}
