function Get-Collector_Exchange_AcceptedDomains {
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-AcceptedDomain }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Domeny akceptowane (Accepted Domains)' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Domeny akceptowane (Accepted Domains)' -Status 'empty' `
            -Description 'Domeny akceptowane skonfigurowane w Exchange Online.'
    }
    $flat = $r.Data | ForEach-Object {
        [PSCustomObject]@{
            'Nazwa'     = $_.DomainName
            'Typ'       = $_.DomainType
            'Domyślna'  = $_.Default
        }
    }
    New-M365TRCollectorResult -Component 'Exchange' -Section 'Domeny akceptowane (Accepted Domains)' `
        -Description 'Domeny akceptowane skonfigurowane w Exchange Online.' -Status 'ok' -Data $flat
}
