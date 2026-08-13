function Get-Collector_Teams_MessagingPolicies {
    <#
    .SYNOPSIS
    Zasady wiadomości Microsoft Teams (edycja/usuwanie wiadomości, GIF-y, naklejki, podglądy
    linków, tłumaczenie) - najważniejsze ustawienia z każdej zasady.
    #>
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-CsTeamsMessagingPolicy }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Teams' -Section 'Zasady wiadomości' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Teams' -Section 'Zasady wiadomości' -Status 'empty' `
            -Description 'Zasady wiadomości Microsoft Teams (edycja/usuwanie, GIF-y, naklejki, podglądy linków, tłumaczenie).'
    }

    $flat = $r.Data | ForEach-Object {
        $parts = New-Object System.Collections.Generic.List[string]
        if ($_.AllowUserChat -eq $false) { $parts.Add('czat użytkownika zablokowany') }
        if ($_.AllowUserEditMessage -eq $false) { $parts.Add('edycja wysłanych wiadomości zablokowana') }
        if ($_.AllowUserDeleteMessage -eq $false) { $parts.Add('usuwanie wysłanych wiadomości zablokowane') }
        if ($_.AllowOwnerDeleteMessage -eq $false) { $parts.Add('usuwanie wiadomości przez właściciela zespołu zablokowane') }
        if ($_.AllowGiphy -eq $false) { $parts.Add('GIF-y (Giphy) zablokowane') }
        if ($_.AllowMemes -eq $false) { $parts.Add('memy zablokowane') }
        if ($_.AllowStickers -eq $false) { $parts.Add('naklejki zablokowane') }
        if ($_.AllowUrlPreviews -eq $false) { $parts.Add('podglądy linków zablokowane') }
        if ($_.AllowUserTranslation -eq $false) { $parts.Add('tłumaczenie wiadomości zablokowane') }
        if ($_.ReadReceiptsEnabledType) { $parts.Add("potwierdzenia odczytu: $($_.ReadReceiptsEnabledType)") }
        $summary = if ($parts.Count -gt 0) { $parts -join '; ' } else { '(domyślne ustawienia, wszystko dozwolone)' }

        [PSCustomObject]@{
            'Nazwa'   = $_.Identity
            'Co robi' = $summary
        }
    }
    New-M365TRCollectorResult -Component 'Teams' -Section 'Zasady wiadomości' `
        -Description 'Zasady wiadomości Microsoft Teams (edycja/usuwanie, GIF-y, naklejki, podglądy linków, tłumaczenie).' -Status 'ok' -Data $flat
}
