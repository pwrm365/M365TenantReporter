function Get-Collector_Exchange_SafeAttachmentPolicies {
    <#
    .SYNOPSIS
    Zasady Safe Attachments (Microsoft Defender for Office 365) - jak traktowane są załączniki
    wykryte jako zlosliwe/podejrzane. Wymaga licencji Defender for Office 365 Plan 1/2 - jeśli
    tenant jej nie posiada, sekcja pojawi się jako pominieta/pusta, a nie błąd.
    #>
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-SafeAttachmentPolicy }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Zasady Safe Attachments (Defender for Office 365)' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Zasady Safe Attachments (Defender for Office 365)' -Status 'empty' `
            -Description 'Zasady Safe Attachments (analiza załączników w piaskownicy) z Microsoft Defender for Office 365.'
    }

    $actionNames = @{
        Block            = 'Blokowanie wiadomości do czasu zakończenia analizy'
        Replace          = 'Usunięcie złośliwego załącznika, dostarczenie wiadomości bez niego'
        Allow            = 'Dostarczenie wiadomości bez oczekiwania na analizę (monitorowanie)'
        DynamicDelivery  = 'Natychmiastowe dostarczenie treści, załącznik dołączany po analizie'
        Monitor          = 'Monitorowanie - wiadomość dostarczana, wynik analizy tylko rejestrowany'
    }

    $flat = $r.Data | ForEach-Object {
        $action = if ($actionNames.ContainsKey("$($_.Action)")) { $actionNames["$($_.Action)"] } else { "$($_.Action)" }
        [PSCustomObject]@{
            'Nazwa'    = $_.Name
            'Domyślna' = $_.IsDefault
            'Włączona' = $_.Enable
            'Akcja'    = $action
        }
    }
    New-M365TRCollectorResult -Component 'Exchange' -Section 'Zasady Safe Attachments (Defender for Office 365)' `
        -Description 'Zasady Safe Attachments (analiza załączników w piaskownicy) z Microsoft Defender for Office 365.' -Status 'ok' -Data $flat
}
