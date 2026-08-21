function Get-Collector_SharePoint_PnpTenantSettings {
    <#
    .SYNOPSIS
    Ustawienia SharePoint na poziomie administracyjnym (Get-PnPTenant) - szerszy zestaw niż to,
    co udostępnia Microsoft Graph (/admin/sharepoint/settings), w tym m.in. limit czasu
    bezczynności (idle session sign-out) i starsze protokoły uwierzytelniania. Pełny zrzut
    właściwości - nic nie jest świadomie ukrywane, nawet jeśli etykieta nie jest jeszcze
    wyselekcjonowana.
    #>
    param([Parameter(Mandatory)]$Context)
    $lang = Get-M365TRLanguage -Context $Context
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-PnPTenant }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'SharePoint' -Section 'Ustawienia SharePoint (poziom administracyjny)' -Status $r.Status -Message $r.Message
    }
    $tenantSettings = $r.Data | Select-Object -First 1
    if (-not $tenantSettings) {
        $emptyDescription = if ($lang -eq 'en') { 'Tenant-wide SharePoint administrative settings.' } else { 'Ustawienia SharePoint na poziomie administracyjnym całego tenanta.' }
        return New-M365TRCollectorResult -Component 'SharePoint' -Section 'Ustawienia SharePoint (poziom administracyjny)' -Status 'empty' -Description $emptyDescription
    }

    $labelMap = if ($lang -eq 'en') {
        @{
            IdleSessionSignOutEnabled     = 'Idle session sign-out enabled'
            IdleSessionSignOutMinutes     = 'Idle session sign-out after (minutes)'
            IdleSessionSignOutWarningAfterMinutes = 'Idle session warning after (minutes)'
            LegacyAuthProtocolsEnabled    = 'Legacy authentication protocols enabled'
            ConditionalAccessPolicy       = 'Conditional access policy'
            AllowedDomainListForSyncClient = 'Domains allowed for OneDrive sync client'
            DisallowInfectedFileDownload  = 'Block download of infected files'
            NotifyOwnersWhenInvitationsAccepted = 'Notify site owners when external invitations are accepted'
            SharingCapability             = 'External sharing capability'
        }
    } else {
        @{
            IdleSessionSignOutEnabled     = 'Wylogowanie po bezczynności włączone'
            IdleSessionSignOutMinutes     = 'Wylogowanie po bezczynności po (minutach)'
            IdleSessionSignOutWarningAfterMinutes = 'Ostrzeżenie o bezczynności po (minutach)'
            LegacyAuthProtocolsEnabled    = 'Starsze protokoły uwierzytelniania włączone'
            ConditionalAccessPolicy       = 'Zasada dostępu warunkowego'
            AllowedDomainListForSyncClient = 'Domeny dozwolone dla klienta synchronizacji OneDrive'
            DisallowInfectedFileDownload  = 'Blokuj pobieranie zainfekowanych plików'
            NotifyOwnersWhenInvitationsAccepted = 'Powiadamiaj właścicieli witryn o zaakceptowanych zaproszeniach zewnętrznych'
            SharingCapability             = 'Poziom udostępniania zewnętrznego'
        }
    }
    $excludeProps = @('PSComputerName', 'PSShowComputerName', 'RunspaceId')

    $rows = @(ConvertTo-M365TRLabeledRows -InputObject $tenantSettings -LabelMap $labelMap -ExcludeProperties $excludeProps -Language $lang)
    if ($rows.Count -eq 0) {
        $emptyDescription = if ($lang -eq 'en') { 'The settings object exists but has no properties.' } else { 'Obiekt ustawień istnieje, ale nie zawiera żadnych właściwości.' }
        return New-M365TRCollectorResult -Component 'SharePoint' -Section 'Ustawienia SharePoint (poziom administracyjny)' -Status 'empty' -Description $emptyDescription
    }

    $description = if ($lang -eq 'en') {
        'Tenant-wide SharePoint administrative settings (via SharePoint Online Management, not Microsoft Graph) - a broader set than the Graph-based sharing settings section, including idle session sign-out and legacy authentication protocols.'
    } else {
        'Ustawienia SharePoint na poziomie administracyjnym całego tenanta (przez SharePoint Online Management, nie Microsoft Graph) - szerszy zestaw niż sekcja ustawień udostępniania oparta na Graph, w tym m.in. wylogowanie po bezczynności i starsze protokoły uwierzytelniania.'
    }
    New-M365TRCollectorResult -Component 'SharePoint' -Section 'Ustawienia SharePoint (poziom administracyjny)' -Description $description -Status 'ok' -Data $rows
}
