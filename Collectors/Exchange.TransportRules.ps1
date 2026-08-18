function Get-M365TRTransportRuleLabelMap {
    param([ValidateSet('pl', 'en')][string]$Language = 'pl')
    if ($Language -eq 'en') {
        return @{
            From                               = 'Condition: sender is'
            FromScope                          = 'Condition: sender scope'
            FromMemberOf                       = 'Condition: sender is member of'
            SentTo                             = 'Condition: recipient is'
            SentToScope                        = 'Condition: recipient scope'
            SentToMemberOf                     = 'Condition: recipient is member of'
            RecipientDomainIs                  = 'Condition: recipient domain is'
            SenderDomainIs                     = 'Condition: sender domain is'
            SenderInRecipientList              = 'Condition: sender is also a recipient'
            RecipientInSenderList              = 'Condition: recipient is also the sender'
            SubjectContainsWords               = 'Condition: subject contains'
            SubjectOrBodyContainsWords         = 'Condition: subject or body contains'
            SubjectMatchesPatterns             = 'Condition: subject matches pattern'
            HeaderContainsMessageHeader        = 'Condition: header name'
            HeaderContainsWords                = 'Condition: header contains'
            HeaderMatchesMessageHeader         = 'Condition: header (regex) name'
            HeaderMatchesPatterns              = 'Condition: header matches pattern'
            AttachmentContainsWords            = 'Condition: attachment contains'
            AttachmentExtensionMatchesWords    = 'Condition: attachment extension'
            AttachmentHasExecutableContent     = 'Condition: attachment has executable content'
            AttachmentIsPasswordProtected      = 'Condition: attachment is password-protected'
            AttachmentSizeOver                 = 'Condition: attachment larger than'
            MessageSizeOver                    = 'Condition: message larger than'
            MessageTypeMatches                 = 'Condition: message type'
            HasClassification                  = 'Condition: message classification'
            WithImportance                     = 'Condition: importance'
            SCLOver                            = 'Condition: spam confidence level (SCL) over'
            ExceptIfFrom                       = 'Exception: sender is'
            ExceptIfFromScope                  = 'Exception: sender scope'
            ExceptIfFromMemberOf               = 'Exception: sender is member of'
            ExceptIfSentTo                     = 'Exception: recipient is'
            ExceptIfSentToScope                = 'Exception: recipient scope'
            ExceptIfSentToMemberOf             = 'Exception: recipient is member of'
            ExceptIfRecipientDomainIs          = 'Exception: recipient domain is'
            ExceptIfSenderDomainIs             = 'Exception: sender domain is'
            ExceptIfSubjectContainsWords       = 'Exception: subject contains'
            ExceptIfSubjectOrBodyContainsWords = 'Exception: subject or body contains'
            ExceptIfHeaderContainsMessageHeader = 'Exception: header name'
            ExceptIfHeaderContainsWords        = 'Exception: header contains'
            ExceptIfAttachmentContainsWords    = 'Exception: attachment contains'
            ExceptIfAttachmentSizeOver         = 'Exception: attachment larger than'
            ExceptIfMessageSizeOver            = 'Exception: message larger than'
            ExceptIfHasClassification          = 'Exception: message classification'
            ExceptIfWithImportance             = 'Exception: importance'
            RejectMessageReasonText            = 'Action: reject with message'
            RejectMessageEnhancedStatusCode    = 'Action: reject status code'
            DeleteMessage                      = 'Action: silently delete message'
            Quarantine                         = 'Action: send to quarantine'
            RedirectMessageTo                  = 'Action: redirect to'
            BlindCopyMessageTo                 = 'Action: Bcc to'
            CopyTo                             = 'Action: Cc to'
            AddToRecipients                    = 'Action: add recipient'
            RemoveFromRecipients                = 'Action: remove recipient'
            PrependSubject                     = 'Action: prepend to subject'
            ApplyClassification                = 'Action: apply classification'
            SetSCL                             = 'Action: set spam confidence level (SCL)'
            SetHeaderName                      = 'Action: set header name'
            SetHeaderValue                     = 'Action: set header value'
            RemoveHeader                       = 'Action: remove header'
            StopRuleProcessing                 = 'Action: stop processing more rules'
            ModerateMessageByUser              = 'Action: require approval from'
            ModerateMessageByManager           = "Action: require approval from sender's manager"
            GenerateIncidentReport             = 'Action: send incident report to'
            IncidentReportOriginalMail         = 'Action: incident report includes original message'
            IncidentReportContent              = 'Action: incident report content'
            ApplyHtmlDisclaimerText            = 'Action: disclaimer text'
            ApplyHtmlDisclaimerLocation        = 'Action: disclaimer location'
            ApplyHtmlDisclaimerFallbackAction  = 'Action: disclaimer fallback action'
            NotifySender                       = 'Action: notify sender'
            RouteMessageOutboundConnector      = 'Action: route via connector'
            RouteMessageOutboundRequireTls     = 'Action: require TLS for outbound routing'
            ApplyRightsProtectionTemplate      = 'Action: apply rights-protection (RMS) template'
            ActivationDate                     = 'Active from'
            ExpiryDate                         = 'Active until'
            RuleErrorAction                    = 'On rule processing error'
            SenderAddressLocation              = 'Sender address checked in'
            RuleSubType                        = 'Rule subtype'
        }
    }
    return @{
        From                               = 'Warunek: nadawca to'
        FromScope                          = 'Warunek: zasięg nadawcy'
        FromMemberOf                       = 'Warunek: nadawca należy do'
        SentTo                             = 'Warunek: odbiorca to'
        SentToScope                        = 'Warunek: zasięg odbiorcy'
        SentToMemberOf                     = 'Warunek: odbiorca należy do'
        RecipientDomainIs                  = 'Warunek: domena odbiorcy to'
        SenderDomainIs                     = 'Warunek: domena nadawcy to'
        SenderInRecipientList              = 'Warunek: nadawca jest też odbiorcą'
        RecipientInSenderList              = 'Warunek: odbiorca jest też nadawcą'
        SubjectContainsWords               = 'Warunek: temat zawiera'
        SubjectOrBodyContainsWords         = 'Warunek: temat lub treść zawiera'
        SubjectMatchesPatterns             = 'Warunek: temat pasuje do wzorca'
        HeaderContainsMessageHeader        = 'Warunek: nazwa nagłówka'
        HeaderContainsWords                = 'Warunek: nagłówek zawiera'
        HeaderMatchesMessageHeader         = 'Warunek: nazwa nagłówka (regex)'
        HeaderMatchesPatterns              = 'Warunek: nagłówek pasuje do wzorca'
        AttachmentContainsWords            = 'Warunek: załącznik zawiera'
        AttachmentExtensionMatchesWords    = 'Warunek: rozszerzenie załącznika'
        AttachmentHasExecutableContent     = 'Warunek: załącznik zawiera treść wykonywalną'
        AttachmentIsPasswordProtected      = 'Warunek: załącznik chroniony hasłem'
        AttachmentSizeOver                 = 'Warunek: załącznik większy niż'
        MessageSizeOver                    = 'Warunek: wiadomość większa niż'
        MessageTypeMatches                 = 'Warunek: typ wiadomości'
        HasClassification                  = 'Warunek: klasyfikacja wiadomości'
        WithImportance                     = 'Warunek: waga wiadomości'
        SCLOver                            = 'Warunek: poziom spamu (SCL) powyżej'
        ExceptIfFrom                       = 'Wyjątek: nadawca to'
        ExceptIfFromScope                  = 'Wyjątek: zasięg nadawcy'
        ExceptIfFromMemberOf               = 'Wyjątek: nadawca należy do'
        ExceptIfSentTo                     = 'Wyjątek: odbiorca to'
        ExceptIfSentToScope                = 'Wyjątek: zasięg odbiorcy'
        ExceptIfSentToMemberOf             = 'Wyjątek: odbiorca należy do'
        ExceptIfRecipientDomainIs          = 'Wyjątek: domena odbiorcy to'
        ExceptIfSenderDomainIs             = 'Wyjątek: domena nadawcy to'
        ExceptIfSubjectContainsWords       = 'Wyjątek: temat zawiera'
        ExceptIfSubjectOrBodyContainsWords = 'Wyjątek: temat lub treść zawiera'
        ExceptIfHeaderContainsMessageHeader = 'Wyjątek: nazwa nagłówka'
        ExceptIfHeaderContainsWords        = 'Wyjątek: nagłówek zawiera'
        ExceptIfAttachmentContainsWords    = 'Wyjątek: załącznik zawiera'
        ExceptIfAttachmentSizeOver         = 'Wyjątek: załącznik większy niż'
        ExceptIfMessageSizeOver            = 'Wyjątek: wiadomość większa niż'
        ExceptIfHasClassification          = 'Wyjątek: klasyfikacja wiadomości'
        ExceptIfWithImportance             = 'Wyjątek: waga wiadomości'
        RejectMessageReasonText            = 'Akcja: odrzuć z komunikatem'
        RejectMessageEnhancedStatusCode    = 'Akcja: kod statusu odrzucenia'
        DeleteMessage                      = 'Akcja: cicho usuń wiadomość'
        Quarantine                         = 'Akcja: przenieś do kwarantanny'
        RedirectMessageTo                  = 'Akcja: przekieruj do'
        BlindCopyMessageTo                 = 'Akcja: UDW do'
        CopyTo                             = 'Akcja: DW do'
        AddToRecipients                    = 'Akcja: dodaj odbiorcę'
        RemoveFromRecipients                = 'Akcja: usuń odbiorcę'
        PrependSubject                     = 'Akcja: dodaj przedrostek do tematu'
        ApplyClassification                = 'Akcja: zastosuj klasyfikację'
        SetSCL                             = 'Akcja: ustaw poziom spamu (SCL)'
        SetHeaderName                      = 'Akcja: ustaw nazwę nagłówka'
        SetHeaderValue                     = 'Akcja: ustaw wartość nagłówka'
        RemoveHeader                       = 'Akcja: usuń nagłówek'
        StopRuleProcessing                 = 'Akcja: zatrzymaj przetwarzanie kolejnych reguł'
        ModerateMessageByUser              = 'Akcja: wymagaj zatwierdzenia przez'
        ModerateMessageByManager           = 'Akcja: wymagaj zatwierdzenia przez przełożonego nadawcy'
        GenerateIncidentReport             = 'Akcja: wyślij raport o incydencie do'
        IncidentReportOriginalMail         = 'Akcja: raport zawiera oryginalną wiadomość'
        IncidentReportContent              = 'Akcja: zawartość raportu incydentu'
        ApplyHtmlDisclaimerText            = 'Akcja: treść zastrzeżenia (disclaimer)'
        ApplyHtmlDisclaimerLocation        = 'Akcja: lokalizacja zastrzeżenia'
        ApplyHtmlDisclaimerFallbackAction  = 'Akcja: akcja zapasowa dla zastrzeżenia'
        NotifySender                       = 'Akcja: powiadom nadawcę'
        RouteMessageOutboundConnector      = 'Akcja: przekieruj przez łącznik'
        RouteMessageOutboundRequireTls     = 'Akcja: wymagaj TLS dla routingu wychodzącego'
        ApplyRightsProtectionTemplate      = 'Akcja: zastosuj szablon ochrony praw (RMS)'
        ActivationDate                     = 'Aktywna od'
        ExpiryDate                         = 'Aktywna do'
        RuleErrorAction                    = 'Przy błędzie przetwarzania reguły'
        SenderAddressLocation              = 'Adres nadawcy sprawdzany w'
        RuleSubType                        = 'Podtyp reguły'
    }
}

function Get-Collector_Exchange_TransportRules {
    <#
    .SYNOPSIS
    Reguły transportu (mail flow) - jedna z bardziej wpływowych, a najsłabiej udokumentowanych
    dotąd sekcji: sama reguła JEST już zasadą zasięgu (warunki na nadawcy/odbiorcy/temacie/
    załącznikach) - nie ma osobnego obiektu przypisania jak w Graph, więc pełny zrzut warunków
    i akcji trafia do jednej tabeli "Ustawienia".
    #>
    param([Parameter(Mandatory)]$Context)
    $lang = Get-M365TRLanguage -Context $Context
    $description = if ($lang -eq 'en') {
        'Mail flow rules configured in Exchange Online - full conditions, exceptions and actions for each rule.'
    } else {
        'Reguły przetwarzania poczty (mail flow) skonfigurowane w Exchange Online - pełne warunki, wyjątki i akcje każdej reguły.'
    }
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-TransportRule }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Reguły transportu (Transport Rules)' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Reguły transportu (Transport Rules)' -Status 'empty' -Description $description
    }

    $labelMap = Get-M365TRTransportRuleLabelMap -Language $lang
    $excludeProps = @(
        'Identity', 'Id', 'Guid', 'DistinguishedName', 'ExchangeVersion', 'ObjectCategory', 'ObjectClass',
        'OrganizationalUnitRoot', 'OriginatingServer', 'IsValid', 'ObjectState', 'RunspaceId',
        'WhenChanged', 'WhenChangedUTC', 'WhenCreated', 'WhenCreatedUTC', 'ImmutableId',
        'Name', 'State', 'Priority', 'Mode', 'Comments', 'Description', 'PSComputerName', 'PSShowComputerName'
    )

    $records = $r.Data | ForEach-Object {
        $basicRows = New-Object System.Collections.Generic.List[object]
        if ($lang -eq 'en') {
            $basicRows.Add([PSCustomObject]@{ 'Ustawienie' = 'State'; 'Wartość' = "$($_.State)" })
            $basicRows.Add([PSCustomObject]@{ 'Ustawienie' = 'Priority'; 'Wartość' = "$($_.Priority)" })
            if ($_.Mode) { $basicRows.Add([PSCustomObject]@{ 'Ustawienie' = 'Mode'; 'Wartość' = "$($_.Mode)" }) }
            if ($_.Comments) { $basicRows.Add([PSCustomObject]@{ 'Ustawienie' = 'Admin comment'; 'Wartość' = "$($_.Comments)" }) }
            if ($_.Description) { $basicRows.Add([PSCustomObject]@{ 'Ustawienie' = 'Auto-generated summary'; 'Wartość' = "$($_.Description)" }) }
        } else {
            $basicRows.Add([PSCustomObject]@{ 'Ustawienie' = 'Stan'; 'Wartość' = "$($_.State)" })
            $basicRows.Add([PSCustomObject]@{ 'Ustawienie' = 'Priorytet'; 'Wartość' = "$($_.Priority)" })
            if ($_.Mode) { $basicRows.Add([PSCustomObject]@{ 'Ustawienie' = 'Tryb'; 'Wartość' = "$($_.Mode)" }) }
            if ($_.Comments) { $basicRows.Add([PSCustomObject]@{ 'Ustawienie' = 'Komentarz administratora'; 'Wartość' = "$($_.Comments)" }) }
            if ($_.Description) { $basicRows.Add([PSCustomObject]@{ 'Ustawienie' = 'Podsumowanie automatyczne'; 'Wartość' = "$($_.Description)" }) }
        }

        $settingsRows = @(ConvertTo-M365TRLabeledRows -InputObject $_ -LabelMap $labelMap -ExcludeProperties $excludeProps -Language $lang)
        if ($settingsRows.Count -eq 0) {
            $settingsRows = @([PSCustomObject]@{
                'Ustawienie' = if ($lang -eq 'en') { 'Conditions/actions' } else { 'Warunki/akcje' }
                'Wartość'    = if ($lang -eq 'en') { '(no additional conditions or actions set)' } else { '(brak dodatkowych warunków lub akcji)' }
            })
        }

        New-M365TRDetailRecord -Name $_.Name -Tables @(
            (New-M365TRDetailTable -Title 'Podstawowe' -Rows $basicRows)
            (New-M365TRDetailTable -Title 'Ustawienia' -Rows $settingsRows)
        )
    }

    New-M365TRCollectorResult -Component 'Exchange' -Section 'Reguły transportu (Transport Rules)' `
        -Description $description -Status 'ok' -Records -Data $records
}
