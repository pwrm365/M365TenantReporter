function Get-Collector_Exchange_SafeLinksPolicies {
    <#
    .SYNOPSIS
    Zasady Safe Links (Microsoft Defender for Office 365) - przepisywanie i skanowanie linków
    w wiadomosciach, Teams i Office. Wymaga licencji Defender for Office 365 Plan 1/2 - jeśli
    tenant jej nie posiada, sekcja pojawi się jako pominieta/pusta, a nie błąd.
    #>
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-SafeLinksPolicy }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Zasady Safe Links (Defender for Office 365)' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Zasady Safe Links (Defender for Office 365)' -Status 'empty' `
            -Description 'Zasady Safe Links (skanowanie i przepisywanie linków) z Microsoft Defender for Office 365.'
    }
    $flat = $r.Data | ForEach-Object {
        $parts = New-Object System.Collections.Generic.List[string]
        if ($_.EnableSafeLinksForEmail -eq $true) { $parts.Add('skanowanie linków w poczcie') }
        if ($_.EnableSafeLinksForTeams -eq $true) { $parts.Add('skanowanie linków w Teams') }
        if ($_.EnableSafeLinksForOffice -eq $true) { $parts.Add('skanowanie linków w plikach Office') }
        if ($_.ScanUrls -eq $true) { $parts.Add('skanowanie adresów URL w czasie kliknięcia') }
        if ($_.EnableForInternalSenders -eq $true) { $parts.Add('dotyczy też nadawców wewnętrznych') }
        if ($_.DeliverMessageAfterScan -eq $true) { $parts.Add('dostarczenie wiadomości dopiero po zakończeniu skanowania') }
        if ($_.DoNotRewriteUrls -and @($_.DoNotRewriteUrls).Count -gt 0) { $parts.Add("adresy wyłączone z przepisywania: $(@($_.DoNotRewriteUrls).Count)") }
        if ($_.AllowClickThrough -eq $true) { $parts.Add('użytkownik może kontynuować mimo ostrzeżenia') }
        $summary = if ($parts.Count -gt 0) { $parts -join '; ' } else { '(domyślne ustawienia, bez dodatkowych włączonych funkcji)' }

        [PSCustomObject]@{
            'Nazwa'      = $_.Name
            'Wbudowana'  = $_.IsBuiltInProtection
            'Co robi'    = $summary
        }
    }
    New-M365TRCollectorResult -Component 'Exchange' -Section 'Zasady Safe Links (Defender for Office 365)' `
        -Description 'Zasady Safe Links (skanowanie i przepisywanie linków) z Microsoft Defender for Office 365.' -Status 'ok' -Data $flat
}
