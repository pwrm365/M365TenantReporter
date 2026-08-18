function Get-M365TRTeamsMessagingPolicyLabelMap {
    param([ValidateSet('pl', 'en')][string]$Language = 'pl')
    if ($Language -eq 'en') {
        return @{
            AllowUserChat                = 'User chat allowed'
            AllowUserEditMessage         = 'Editing sent messages allowed'
            AllowUserDeleteMessage       = 'Deleting sent messages allowed'
            AllowOwnerDeleteMessage      = 'Team owner can delete messages'
            AllowGiphy                   = 'GIFs (Giphy) allowed'
            GiphyRatingType              = 'Giphy content rating'
            AllowMemes                   = 'Memes allowed'
            AllowStickers                = 'Stickers allowed'
            AllowUrlPreviews             = 'Link previews allowed'
            AllowUserTranslation         = 'Message translation allowed'
            AllowImmersiveReader         = 'Immersive Reader allowed'
            ReadReceiptsEnabledType      = 'Read receipts'
            AllowPriorityMessages        = 'Priority (urgent) messages allowed'
            AllowSmartReply              = 'Suggested/smart replies allowed'
            AllowUserEditScheduledMeetingMessage = 'Editing scheduled-meeting invite message allowed'
            AllowRemoveUser              = 'Removing users from chat allowed'
            AllowSecurityEndUserReporting = 'End users can report messages as security concerns'
            Description                  = 'Admin description'
        }
    }
    return @{
        AllowUserChat                = 'Czat użytkownika dozwolony'
        AllowUserEditMessage         = 'Edycja wysłanych wiadomości dozwolona'
        AllowUserDeleteMessage       = 'Usuwanie wysłanych wiadomości dozwolone'
        AllowOwnerDeleteMessage      = 'Właściciel zespołu może usuwać wiadomości'
        AllowGiphy                   = 'GIF-y (Giphy) dozwolone'
        GiphyRatingType              = 'Poziom treści Giphy'
        AllowMemes                   = 'Memy dozwolone'
        AllowStickers                = 'Naklejki dozwolone'
        AllowUrlPreviews             = 'Podglądy linków dozwolone'
        AllowUserTranslation         = 'Tłumaczenie wiadomości dozwolone'
        AllowImmersiveReader         = 'Immersive Reader dozwolony'
        ReadReceiptsEnabledType      = 'Potwierdzenia odczytu'
        AllowPriorityMessages        = 'Wiadomości priorytetowe (pilne) dozwolone'
        AllowSmartReply              = 'Sugerowane/inteligentne odpowiedzi dozwolone'
        AllowUserEditScheduledMeetingMessage = 'Edycja wiadomości zaproszenia na spotkanie dozwolona'
        AllowRemoveUser              = 'Usuwanie użytkowników z czatu dozwolone'
        AllowSecurityEndUserReporting = 'Użytkownicy mogą zgłaszać wiadomości jako podejrzane'
        Description                  = 'Opis administratora'
    }
}

function Get-Collector_Teams_MessagingPolicies {
    <#
    .SYNOPSIS
    Zasady wiadomości Microsoft Teams - pełny zrzut ustawień każdej zasady (edycja/usuwanie
    wiadomości, GIF-y, naklejki, podglądy linków, tłumaczenie i pozostałe przełączniki).
    #>
    param([Parameter(Mandatory)]$Context)
    $lang = Get-M365TRLanguage -Context $Context
    $description = if ($lang -eq 'en') {
        'Microsoft Teams messaging policies (edit/delete, GIFs, stickers, link previews, translation) - full settings for each policy.'
    } else {
        'Zasady wiadomości Microsoft Teams (edycja/usuwanie, GIF-y, naklejki, podglądy linków, tłumaczenie) - pełny zrzut ustawień każdej zasady.'
    }
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-CsTeamsMessagingPolicy }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Teams' -Section 'Zasady wiadomości' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Teams' -Section 'Zasady wiadomości' -Status 'empty' -Description $description
    }

    $labelMap = Get-M365TRTeamsMessagingPolicyLabelMap -Language $lang
    $excludeProps = @('Identity', 'Key', 'RunspaceId', 'PSComputerName', 'PSShowComputerName', 'Element', 'CimClass', 'CimInstanceProperties', 'CimSystemProperties')

    $records = $r.Data | ForEach-Object {
        $settingsRows = @(ConvertTo-M365TRLabeledRows -InputObject $_ -LabelMap $labelMap -ExcludeProperties $excludeProps -Language $lang)
        New-M365TRDetailRecord -Name $_.Identity -Tables @(
            (New-M365TRDetailTable -Title 'Ustawienia' -Rows $settingsRows)
        )
    }
    New-M365TRCollectorResult -Component 'Teams' -Section 'Zasady wiadomości' `
        -Description $description -Status 'ok' -Records -Data $records
}
