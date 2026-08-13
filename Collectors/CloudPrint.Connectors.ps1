function Get-Collector_CloudPrint_Connectors {
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/print/connectors'
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'CloudPrint' -Section 'Konektory' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'CloudPrint' -Section 'Konektory' -Status 'empty' `
            -Description 'Konektory Universal Print.'
    }
    $flat = $r.Data | ForEach-Object {
        [PSCustomObject]@{
            'Nazwa'  = $_.displayName
            'Status' = $_.status
        }
    }
    New-M365TRCollectorResult -Component 'CloudPrint' -Section 'Konektory' `
        -Description 'Konektory Universal Print.' -Status 'ok' -Data $flat
}
