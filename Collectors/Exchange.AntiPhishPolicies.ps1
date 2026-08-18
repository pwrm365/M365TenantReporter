function Get-Collector_Exchange_AntiPhishPolicies {
    param([Parameter(Mandatory)]$Context)
    $lang = Get-M365TRLanguage -Context $Context
    $description = if ($lang -eq 'en') {
        'Anti-phishing protection policies configured in Exchange Online - full settings and scope (rule linked to each policy).'
    } else {
        'Zasady ochrony przed phishingiem skonfigurowane w Exchange Online - pełne ustawienia oraz zasięg (reguła powiązana z każdą zasadą).'
    }
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-AntiPhishPolicy }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Zasady Anti-Phishing' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Zasady Anti-Phishing' -Status 'empty' -Description $description
    }

    $rulesResult = Invoke-M365TREXOCommand -ScriptBlock { Get-AntiPhishRule }
    $rules = if ($rulesResult.Success) { @($rulesResult.Data) } else { @() }
    $labelMap = Get-M365TREXOSecurityPolicyLabelMap -Language $lang
    $excludeProps = @(
        'Identity', 'Id', 'Guid', 'DistinguishedName', 'ExchangeVersion', 'ObjectCategory', 'ObjectClass',
        'OrganizationalUnitRoot', 'OriginatingServer', 'IsValid', 'ObjectState', 'RunspaceId',
        'WhenChanged', 'WhenChangedUTC', 'WhenCreated', 'WhenCreatedUTC', 'ImmutableId',
        'Name', 'IsDefault', 'Enabled', 'PSComputerName', 'PSShowComputerName',
        'ObjectVersion', 'CreatedBy', 'LastModifiedBy', 'ReadOnly', 'DistributionStatus',
        'DistributionSyncStatus', 'ModificationTimeUtc', 'CreationTimeUtc',
        'DirectoryObjectVersion', 'ExchangeObjectId', 'OrganizationId', 'RecommendedPolicyType'
    )

    $records = $r.Data | ForEach-Object {
        $policyName = $_.Name
        $basicRows = @(
            [PSCustomObject]@{ 'Ustawienie' = if ($lang -eq 'en') { 'Default policy' } else { 'Zasada domyślna' }; 'Wartość' = "$($_.IsDefault)" }
            [PSCustomObject]@{ 'Ustawienie' = if ($lang -eq 'en') { 'Enabled' } else { 'Włączona' }; 'Wartość' = "$($_.Enabled)" }
        )
        $settingsRows = @(ConvertTo-M365TRLabeledRows -InputObject $_ -LabelMap $labelMap -ExcludeProperties $excludeProps -Language $lang)
        $rule = $rules | Where-Object { $_.AntiPhishPolicy -eq $policyName } | Select-Object -First 1
        $assignRows = @(Get-M365TREXORuleAssignmentRows -Rule $rule -Language $lang)

        New-M365TRDetailRecord -Name $policyName -Tables @(
            (New-M365TRDetailTable -Title 'Podstawowe' -Rows $basicRows)
            (New-M365TRDetailTable -Title 'Ustawienia' -Rows $settingsRows)
            (New-M365TRDetailTable -Title 'Przypisania' -Rows $assignRows)
        )
    }

    New-M365TRCollectorResult -Component 'Exchange' -Section 'Zasady Anti-Phishing' `
        -Description $description -Status 'ok' -Records -Data $records
}
