function Get-M365TROutboundConnectorSummary {
    param($Connector)
    $parts = New-Object System.Collections.Generic.List[string]

    if (@($Connector.RecipientDomains).Count -gt 0) { $parts.Add("domeny docelowe: $(@($Connector.RecipientDomains) -join ', ')") }
    if (@($Connector.SmartHosts).Count -gt 0) { $parts.Add("przez smart host: $(@($Connector.SmartHosts) -join ', ')") }
    if ($Connector.TlsSettings) { $parts.Add("TLS: $($Connector.TlsSettings)") }
    if ($Connector.RouteAllMessagesViaOnPremises -eq $true) { $parts.Add('caly ruch routowany przez serwery on-premises') }
    if ($Connector.IsTransportRuleScoped -eq $true) { $parts.Add('używany tylko przez regule transportu (scoped)') }

    if ($parts.Count -eq 0) { return '(brak kluczowych ustawien do podsumowania)' }
    return ($parts -join '; ')
}

function Get-Collector_Exchange_OutboundConnectors {
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-OutboundConnector }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Konektory wychodzące (Outbound Connectors)' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Konektory wychodzące (Outbound Connectors)' -Status 'empty' `
            -Description 'Konektory wychodzące skonfigurowane w Exchange Online.'
    }
    $flat = $r.Data | ForEach-Object {
        [PSCustomObject]@{
            'Nazwa'    = $_.Name
            'Włączony' = $_.Enabled
            'Co robi'  = Get-M365TROutboundConnectorSummary -Connector $_
        }
    }
    New-M365TRCollectorResult -Component 'Exchange' -Section 'Konektory wychodzące (Outbound Connectors)' `
        -Description 'Konektory wychodzące skonfigurowane w Exchange Online.' -Status 'ok' -Data $flat
}
