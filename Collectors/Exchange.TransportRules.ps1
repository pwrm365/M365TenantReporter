function Get-Collector_Exchange_TransportRules {
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-TransportRule }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Reguły transportu (Transport Rules)' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Reguły transportu (Transport Rules)' -Status 'empty' `
            -Description 'Reguły przetwarzania poczty (mail flow) skonfigurowane w Exchange Online.'
    }
    $flat = $r.Data | ForEach-Object {
        [PSCustomObject]@{
            'Nazwa'     = $_.Name
            'Stan'      = $_.State
            'Priorytet' = $_.Priority
            'Opis'      = $_.Description
        }
    }
    New-M365TRCollectorResult -Component 'Exchange' -Section 'Reguły transportu (Transport Rules)' `
        -Description 'Reguły przetwarzania poczty (mail flow) skonfigurowane w Exchange Online.' -Status 'ok' -Data $flat
}
