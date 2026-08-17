function Get-Collector_Exchange_AntiSpamPolicies {
    param([Parameter(Mandatory)]$Context)
    $lang = Get-M365TRLanguage -Context $Context
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-HostedContentFilterPolicy }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Zasady Anti-Spam (Content Filter)' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Zasady Anti-Spam (Content Filter)' -Status 'empty' `
            -Description 'Zasady filtrowania spamu skonfigurowane w Exchange Online.'
    }
    $flat = $r.Data | ForEach-Object {
        $parts = New-Object System.Collections.Generic.List[string]
        if ($lang -eq 'en') {
            $parts.Add("spam -> $($_.SpamAction)")
            $parts.Add("high-confidence spam -> $($_.HighConfidenceSpamAction)")
            if ($_.PhishSpamAction) { $parts.Add("phishing -> $($_.PhishSpamAction)") }
            if ($_.BulkSpamAction) { $parts.Add("bulk mail -> $($_.BulkSpamAction) (threshold: $($_.BulkThreshold))") }
        } else {
            $parts.Add("spam -> $($_.SpamAction)")
            $parts.Add("wysoki spam -> $($_.HighConfidenceSpamAction)")
            if ($_.PhishSpamAction) { $parts.Add("phishing -> $($_.PhishSpamAction)") }
            if ($_.BulkSpamAction) { $parts.Add("masowa wysylka -> $($_.BulkSpamAction) (prog: $($_.BulkThreshold))") }
        }

        [PSCustomObject]@{
            'Nazwa'   = $_.Name
            'Co robi' = ($parts -join '; ')
        }
    }
    New-M365TRCollectorResult -Component 'Exchange' -Section 'Zasady Anti-Spam (Content Filter)' `
        -Description 'Zasady filtrowania spamu skonfigurowane w Exchange Online.' -Status 'ok' -Data $flat
}
