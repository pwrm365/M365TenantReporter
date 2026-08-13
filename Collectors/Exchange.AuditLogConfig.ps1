function Get-Collector_Exchange_AuditLogConfig {
    <#
    .SYNOPSIS
    Czy rejestrowanie zdarzeń w Unified Audit Log jest włączone dla tego tenanta - podstawowy
    warunek działania większości narzędzi śledczych/zgodności (Purview, eDiscovery, alerty).
    #>
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-AdminAuditLogConfig }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Rejestrowanie zdarzeń (Unified Audit Log)' -Status $r.Status -Message $r.Message
    }
    $cfg = $r.Data | Select-Object -First 1
    if (-not $cfg) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Rejestrowanie zdarzeń (Unified Audit Log)' -Status 'empty' `
            -Description 'Stan rejestrowania zdarzeń w Unified Audit Log.'
    }
    $rows = @([PSCustomObject]@{ 'Ustawienie' = 'Unified Audit Log'; 'Wartość' = if ($cfg.UnifiedAuditLogIngestionEnabled) { 'Włączony' } else { 'Wyłączony' } })
    New-M365TRCollectorResult -Component 'Exchange' -Section 'Rejestrowanie zdarzeń (Unified Audit Log)' `
        -Description 'Stan rejestrowania zdarzeń w Unified Audit Log - warunek działania większości narzędzi śledczych i zgodności (Purview, eDiscovery, alerty).' `
        -Status 'ok' -Data $rows
}
