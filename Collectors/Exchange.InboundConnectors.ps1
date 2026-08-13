function Get-M365TRInboundConnectorSummary {
    param($Connector)
    $parts = New-Object System.Collections.Generic.List[string]

    if (@($Connector.SenderDomains).Count -gt 0) { $parts.Add("domeny nadawcy: $(@($Connector.SenderDomains) -join ', ')") }
    if ($Connector.RequireTls -eq $true) { $parts.Add('wymaga TLS') }
    if ($Connector.RestrictDomainsToIPAddresses -eq $true) {
        if (@($Connector.SenderIPAddresses).Count -gt 0) {
            $parts.Add("ograniczone do adresów IP: $(@($Connector.SenderIPAddresses) -join ', ')")
        } else {
            $parts.Add('ograniczone do adresów IP')
        }
    }
    if ($Connector.CloudServicesMailEnabled -eq $true) { $parts.Add('obsluguje poczte z zaufanych uslug chmurowych (Enhanced Filtering)') }
    if ($Connector.ConnectorType) { $parts.Add("typ: $($Connector.ConnectorType)") }

    if ($parts.Count -eq 0) { return '(brak kluczowych ustawien do podsumowania)' }
    return ($parts -join '; ')
}

function Get-Collector_Exchange_InboundConnectors {
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-InboundConnector }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Konektory przychodzące (Inbound Connectors)' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Konektory przychodzące (Inbound Connectors)' -Status 'empty' `
            -Description 'Konektory przychodzące skonfigurowane w Exchange Online.'
    }
    $flat = $r.Data | ForEach-Object {
        [PSCustomObject]@{
            'Nazwa'    = $_.Name
            'Włączony' = $_.Enabled
            'Co robi'  = Get-M365TRInboundConnectorSummary -Connector $_
        }
    }
    New-M365TRCollectorResult -Component 'Exchange' -Section 'Konektory przychodzące (Inbound Connectors)' `
        -Description 'Konektory przychodzące skonfigurowane w Exchange Online.' -Status 'ok' -Data $flat
}
