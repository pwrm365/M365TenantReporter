function Get-Collector_Exchange_SafeLinksPolicies {
    <#
    .SYNOPSIS
    Zasady Safe Links (Microsoft Defender for Office 365) - przepisywanie i skanowanie linków
    w wiadomosciach, Teams i Office. Wymaga licencji Defender for Office 365 Plan 1/2 - jeśli
    tenant jej nie posiada, sekcja pojawi się jako pominieta/pusta, a nie błąd.
    #>
    param([Parameter(Mandatory)]$Context)
    $lang = Get-M365TRLanguage -Context $Context
    $description = if ($lang -eq 'en') {
        'Safe Links policies (link scanning and rewriting) from Microsoft Defender for Office 365 - full settings and scope.'
    } else {
        'Zasady Safe Links (skanowanie i przepisywanie linków) z Microsoft Defender for Office 365 - pełne ustawienia oraz zasięg.'
    }
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-SafeLinksPolicy }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Zasady Safe Links (Defender for Office 365)' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Zasady Safe Links (Defender for Office 365)' -Status 'empty' -Description $description
    }

    $rulesResult = Invoke-M365TREXOCommand -ScriptBlock { Get-SafeLinksRule }
    $rules = if ($rulesResult.Success) { @($rulesResult.Data) } else { @() }
    $labelMap = Get-M365TREXOSecurityPolicyLabelMap -Language $lang
    $excludeProps = @(
        'Identity', 'Id', 'Guid', 'DistinguishedName', 'ExchangeVersion', 'ObjectCategory', 'ObjectClass',
        'OrganizationalUnitRoot', 'OriginatingServer', 'IsValid', 'ObjectState', 'RunspaceId',
        'WhenChanged', 'WhenChangedUTC', 'WhenCreated', 'WhenCreatedUTC', 'ImmutableId',
        'Name', 'IsBuiltInProtection', 'PSComputerName', 'PSShowComputerName',
        'ObjectVersion', 'CreatedBy', 'LastModifiedBy', 'ReadOnly', 'DistributionStatus',
        'DistributionSyncStatus', 'ModificationTimeUtc', 'CreationTimeUtc',
        'DirectoryObjectVersion', 'ExchangeObjectId', 'OrganizationId', 'RecommendedPolicyType'
    )

    $records = $r.Data | ForEach-Object {
        $policyName = $_.Name
        $basicRows = @(
            [PSCustomObject]@{ 'Ustawienie' = if ($lang -eq 'en') { 'Built-in protection' } else { 'Wbudowana ochrona' }; 'Wartość' = "$($_.IsBuiltInProtection)" }
        )
        $settingsRows = @(ConvertTo-M365TRLabeledRows -InputObject $_ -LabelMap $labelMap -ExcludeProperties $excludeProps -Language $lang)
        $rule = $rules | Where-Object { $_.SafeLinksPolicy -eq $policyName } | Select-Object -First 1
        $assignRows = @(Get-M365TREXORuleAssignmentRows -Rule $rule -Language $lang)

        New-M365TRDetailRecord -Name $policyName -Tables @(
            (New-M365TRDetailTable -Title 'Podstawowe' -Rows $basicRows)
            (New-M365TRDetailTable -Title 'Ustawienia' -Rows $settingsRows)
            (New-M365TRDetailTable -Title 'Przypisania' -Rows $assignRows)
        )
    }

    New-M365TRCollectorResult -Component 'Exchange' -Section 'Zasady Safe Links (Defender for Office 365)' `
        -Description $description -Status 'ok' -Records -Data $records
}
