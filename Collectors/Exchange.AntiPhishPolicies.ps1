function Get-Collector_Exchange_AntiPhishPolicies {
    param([Parameter(Mandatory)]$Context)
    $lang = Get-M365TRLanguage -Context $Context
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-AntiPhishPolicy }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Zasady Anti-Phishing' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Zasady Anti-Phishing' -Status 'empty' `
            -Description 'Zasady ochrony przed phishingiem skonfigurowane w Exchange Online.'
    }
    $flat = $r.Data | ForEach-Object {
        $parts = New-Object System.Collections.Generic.List[string]
        if ($lang -eq 'en') {
            if ($_.EnableSpoofIntelligence -eq $true) { $parts.Add('spoof detection') }
            if ($_.EnableMailboxIntelligence -eq $true) { $parts.Add('mailbox intelligence (detects unusual senders)') }
            if ($_.EnableTargetedUserProtection -eq $true) { $parts.Add('protection for specified users (impersonation)') }
            if ($_.EnableOrganizationDomainsProtection -eq $true) { $parts.Add('protects organization domains from impersonation') }
            if ($_.PhishThresholdLevel) { $parts.Add("aggressiveness threshold: $($_.PhishThresholdLevel)") }
            if ($_.AuthenticationFailAction) { $parts.Add("on authentication failure: $($_.AuthenticationFailAction)") }
            $summary = if ($parts.Count -gt 0) { $parts -join '; ' } else { '(default settings, no additional features enabled)' }
        } else {
            if ($_.EnableSpoofIntelligence -eq $true) { $parts.Add('wykrywanie spoofingu') }
            if ($_.EnableMailboxIntelligence -eq $true) { $parts.Add('inteligencja skrzynki (wykrywanie nietypowych nadawców)') }
            if ($_.EnableTargetedUserProtection -eq $true) { $parts.Add('ochrona wskazanych użytkowników (impersonacja)') }
            if ($_.EnableOrganizationDomainsProtection -eq $true) { $parts.Add('ochrona domen organizacji przed impersonacja') }
            if ($_.PhishThresholdLevel) { $parts.Add("prog agresywności: $($_.PhishThresholdLevel)") }
            if ($_.AuthenticationFailAction) { $parts.Add("przy niepowodzeniu uwierzytelniania: $($_.AuthenticationFailAction)") }
            $summary = if ($parts.Count -gt 0) { $parts -join '; ' } else { '(domyślne ustawienia, bez dodatkowych włączonych funkcji)' }
        }

        [PSCustomObject]@{
            'Nazwa'    = $_.Name
            'Domyślna' = $_.IsDefault
            'Włączony' = $_.Enabled
            'Co robi'  = $summary
        }
    }
    New-M365TRCollectorResult -Component 'Exchange' -Section 'Zasady Anti-Phishing' `
        -Description 'Zasady ochrony przed phishingiem skonfigurowane w Exchange Online.' -Status 'ok' -Data $flat
}
