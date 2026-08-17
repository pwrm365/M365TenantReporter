function Get-Collector_Exchange_AuthenticationPolicies {
    <#
    .SYNOPSIS
    Zasady uwierzytelniania Exchange Online - czy stare, niezabezpieczone protokoły logowania
    (Basic Auth: POP3, IMAP4, SMTP AUTH, ActiveSync itd.) są jawnie dozwolone czy zablokowane per
    zasada. Brak niestandardowych zasad jest normalnym stanem (Microsoft domyślnie blokuje Basic
    Auth globalnie dla większości protokołów od 2022 r., bez potrzeby tworzenia własnej zasady).
    #>
    param([Parameter(Mandatory)]$Context)
    $lang = Get-M365TRLanguage -Context $Context
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-AuthenticationPolicy }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Zasady uwierzytelniania (Basic Auth)' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Zasady uwierzytelniania (Basic Auth)' -Status 'empty' `
            -Description 'Niestandardowe zasady uwierzytelniania (blokada protokołów Basic Auth: POP3, IMAP4, SMTP AUTH, ActiveSync itd.) w Exchange Online. Brak takich zasad jest normalnym stanem - Microsoft domyślnie blokuje Basic Auth globalnie dla większości protokołów.'
    }

    $protocolLabels = if ($lang -eq 'en') {
        @{
            AllowBasicAuthActiveSync           = 'Exchange ActiveSync'
            AllowBasicAuthAutodiscover         = 'Autodiscover'
            AllowBasicAuthImap                 = 'IMAP4'
            AllowBasicAuthMapi                 = 'MAPI'
            AllowBasicAuthOfflineAddressBook   = 'Offline Address Book'
            AllowBasicAuthOutlookService       = 'Outlook Service'
            AllowBasicAuthPop                  = 'POP3'
            AllowBasicAuthReportingWebServices = 'Reporting Web Services'
            AllowBasicAuthRpc                  = 'RPC'
            AllowBasicAuthSmtp                 = 'SMTP AUTH'
            AllowBasicAuthWebServices          = 'Exchange Web Services (EWS)'
            AllowBasicAuthPowershell           = 'PowerShell'
        }
    } else {
        @{
            AllowBasicAuthActiveSync           = 'Exchange ActiveSync'
            AllowBasicAuthAutodiscover         = 'Autodiscover'
            AllowBasicAuthImap                 = 'IMAP4'
            AllowBasicAuthMapi                 = 'MAPI'
            AllowBasicAuthOfflineAddressBook   = 'Adresowa książka offline'
            AllowBasicAuthOutlookService       = 'Usługa Outlook'
            AllowBasicAuthPop                  = 'POP3'
            AllowBasicAuthReportingWebServices = 'Usługi raportowania'
            AllowBasicAuthRpc                  = 'RPC'
            AllowBasicAuthSmtp                 = 'SMTP AUTH'
            AllowBasicAuthWebServices          = 'Exchange Web Services (EWS)'
            AllowBasicAuthPowershell           = 'PowerShell'
        }
    }
    $noneLabel = if ($lang -eq 'en') { 'None (all Basic Auth protocols blocked)' } else { 'Żaden (wszystkie protokoły Basic Auth zablokowane)' }

    $flat = $r.Data | ForEach-Object {
        $policy = $_
        $parts = New-Object System.Collections.Generic.List[string]
        foreach ($propName in $protocolLabels.Keys) {
            $prop = $policy.PSObject.Properties[$propName]
            if ($prop -and $prop.Value -eq $true) { $parts.Add($protocolLabels[$propName]) }
        }
        $allowed = if ($parts.Count -gt 0) { $parts -join ', ' } else { $noneLabel }
        [PSCustomObject]@{
            'Nazwa'                              = $policy.Name
            'Protokoły z dozwolonym Basic Auth'  = $allowed
        }
    }
    New-M365TRCollectorResult -Component 'Exchange' -Section 'Zasady uwierzytelniania (Basic Auth)' `
        -Description 'Niestandardowe zasady uwierzytelniania Exchange Online - które protokoły logowania Basic Auth (POP3, IMAP4, SMTP AUTH, ActiveSync itd.) są w nich jawnie dozwolone.' `
        -Status 'ok' -Data $flat
}
