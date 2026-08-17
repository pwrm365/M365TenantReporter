function Get-M365TRInboundConnectorSummary {
    param($Connector, [ValidateSet('pl', 'en')][string]$Language = 'pl')
    $parts = New-Object System.Collections.Generic.List[string]

    if ($Language -eq 'en') {
        if (@($Connector.SenderDomains).Count -gt 0) { $parts.Add("sender domains: $(@($Connector.SenderDomains) -join ', ')") }
        if ($Connector.RequireTls -eq $true) { $parts.Add('requires TLS') }
        if ($Connector.RestrictDomainsToIPAddresses -eq $true) {
            if (@($Connector.SenderIPAddresses).Count -gt 0) {
                $parts.Add("restricted to IP addresses: $(@($Connector.SenderIPAddresses) -join ', ')")
            } else {
                $parts.Add('restricted to specific IP addresses')
            }
        }
        if ($Connector.CloudServicesMailEnabled -eq $true) { $parts.Add('handles mail from trusted cloud services (Enhanced Filtering)') }
        if ($Connector.ConnectorType) { $parts.Add("type: $($Connector.ConnectorType)") }
        if ($parts.Count -eq 0) { return '(no key settings to summarize)' }
    } else {
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
    }
    return ($parts -join '; ')
}

function Get-Collector_Exchange_InboundConnectors {
    param([Parameter(Mandatory)]$Context)
    $lang = Get-M365TRLanguage -Context $Context
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
            'Co robi'  = Get-M365TRInboundConnectorSummary -Connector $_ -Language $lang
        }
    }
    New-M365TRCollectorResult -Component 'Exchange' -Section 'Konektory przychodzące (Inbound Connectors)' `
        -Description 'Konektory przychodzące skonfigurowane w Exchange Online.' -Status 'ok' -Data $flat
}
