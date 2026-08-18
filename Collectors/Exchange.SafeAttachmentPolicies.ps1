function Get-Collector_Exchange_SafeAttachmentPolicies {
    <#
    .SYNOPSIS
    Zasady Safe Attachments (Microsoft Defender for Office 365) - jak traktowane są załączniki
    wykryte jako zlosliwe/podejrzane. Wymaga licencji Defender for Office 365 Plan 1/2 - jeśli
    tenant jej nie posiada, sekcja pojawi się jako pominieta/pusta, a nie błąd.
    #>
    param([Parameter(Mandatory)]$Context)
    $lang = Get-M365TRLanguage -Context $Context
    $description = if ($lang -eq 'en') {
        'Safe Attachments policies (sandbox attachment detonation) from Microsoft Defender for Office 365 - full settings and scope.'
    } else {
        'Zasady Safe Attachments (analiza załączników w piaskownicy) z Microsoft Defender for Office 365 - pełne ustawienia oraz zasięg.'
    }
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-SafeAttachmentPolicy }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Zasady Safe Attachments (Defender for Office 365)' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Zasady Safe Attachments (Defender for Office 365)' -Status 'empty' -Description $description
    }

    $rulesResult = Invoke-M365TREXOCommand -ScriptBlock { Get-SafeAttachmentRule }
    $rules = if ($rulesResult.Success) { @($rulesResult.Data) } else { @() }
    $labelMap = Get-M365TREXOSecurityPolicyLabelMap -Language $lang
    $excludeProps = @(
        'Identity', 'Id', 'Guid', 'DistinguishedName', 'ExchangeVersion', 'ObjectCategory', 'ObjectClass',
        'OrganizationalUnitRoot', 'OriginatingServer', 'IsValid', 'ObjectState', 'RunspaceId',
        'WhenChanged', 'WhenChangedUTC', 'WhenCreated', 'WhenCreatedUTC', 'ImmutableId',
        'Name', 'IsDefault', 'Enable', 'Action', 'PSComputerName', 'PSShowComputerName',
        'ObjectVersion', 'CreatedBy', 'LastModifiedBy', 'ReadOnly', 'DistributionStatus',
        'DistributionSyncStatus', 'ModificationTimeUtc', 'CreationTimeUtc',
        'DirectoryObjectVersion', 'ExchangeObjectId', 'OrganizationId', 'RecommendedPolicyType'
    )

    $actionNamesPl = @{
        Block            = 'Blokowanie wiadomości do czasu zakończenia analizy'
        Replace          = 'Usunięcie złośliwego załącznika, dostarczenie wiadomości bez niego'
        Allow            = 'Dostarczenie wiadomości bez oczekiwania na analizę (monitorowanie)'
        DynamicDelivery  = 'Natychmiastowe dostarczenie treści, załącznik dołączany po analizie'
        Monitor          = 'Monitorowanie - wiadomość dostarczana, wynik analizy tylko rejestrowany'
    }
    $actionNamesEn = @{
        Block            = 'Block the message until scanning completes'
        Replace          = 'Remove the malicious attachment, deliver the message without it'
        Allow            = 'Deliver the message without waiting for scanning (monitor only)'
        DynamicDelivery  = 'Deliver the message body immediately, attach the file after scanning'
        Monitor          = 'Monitor only - message is delivered, scan result is just logged'
    }
    $actionNames = if ($lang -eq 'en') { $actionNamesEn } else { $actionNamesPl }

    $records = $r.Data | ForEach-Object {
        $policyName = $_.Name
        $action = if ($actionNames.ContainsKey("$($_.Action)")) { $actionNames["$($_.Action)"] } else { "$($_.Action)" }
        $basicRows = @(
            [PSCustomObject]@{ 'Ustawienie' = if ($lang -eq 'en') { 'Default policy' } else { 'Zasada domyślna' }; 'Wartość' = "$($_.IsDefault)" }
            [PSCustomObject]@{ 'Ustawienie' = if ($lang -eq 'en') { 'Enabled' } else { 'Włączona' }; 'Wartość' = "$($_.Enable)" }
            [PSCustomObject]@{ 'Ustawienie' = if ($lang -eq 'en') { 'Action' } else { 'Akcja' }; 'Wartość' = $action }
        )
        $settingsRows = @(ConvertTo-M365TRLabeledRows -InputObject $_ -LabelMap $labelMap -ExcludeProperties $excludeProps -Language $lang)
        $rule = $rules | Where-Object { $_.SafeAttachmentPolicy -eq $policyName } | Select-Object -First 1
        $assignRows = @(Get-M365TREXORuleAssignmentRows -Rule $rule -Language $lang)

        New-M365TRDetailRecord -Name $policyName -Tables @(
            (New-M365TRDetailTable -Title 'Podstawowe' -Rows $basicRows)
            (New-M365TRDetailTable -Title 'Ustawienia' -Rows $settingsRows)
            (New-M365TRDetailTable -Title 'Przypisania' -Rows $assignRows)
        )
    }

    New-M365TRCollectorResult -Component 'Exchange' -Section 'Zasady Safe Attachments (Defender for Office 365)' `
        -Description $description -Status 'ok' -Records -Data $records
}
