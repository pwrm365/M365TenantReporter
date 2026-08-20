function Get-Collector_Exchange_RemoteDomains {
    <#
    .SYNOPSIS
    Zdalne domeny (Remote Domains) - kontrolują czy wiadomości spoza organizacji mogą wywołać
    autoprzekazywanie i autoodpowiedzi (Poza biurem) na zewnątrz. Domyślna domena "*" dotyczy
    wszystkich odbiorców niepokrytych bardziej szczegółową wpisem.
    #>
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-RemoteDomain }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Zdalne domeny (Remote Domains)' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Zdalne domeny (Remote Domains)' -Status 'empty' `
            -Description 'Zdalne domeny (Remote Domains) kontrolujące autoprzekazywanie i autoodpowiedzi na zewnątrz organizacji.'
    }
    $flat = $r.Data | ForEach-Object {
        [PSCustomObject]@{
            'Nazwa domeny'                            = $_.DomainName
            'Wewnętrzna'                               = $_.IsInternal
            'Autoprzekazywanie na zewnątrz dozwolone'  = $_.AutoForwardEnabled
            'Autoodpowiedzi na zewnątrz dozwolone'     = $_.AutoReplyEnabled
            'Powiadomienia o przekierowaniu spotkań'   = $_.MeetingForwardNotificationEnabled
            'Dozwolony format Poza biurem (OOF)'       = $_.AllowedOOFType
        }
    }
    New-M365TRCollectorResult -Component 'Exchange' -Section 'Zdalne domeny (Remote Domains)' `
        -Description 'Zdalne domeny (Remote Domains) kontrolujące autoprzekazywanie wiadomości i autoodpowiedzi (Poza biurem) na zewnątrz organizacji.' `
        -Status 'ok' -Data $flat
}
