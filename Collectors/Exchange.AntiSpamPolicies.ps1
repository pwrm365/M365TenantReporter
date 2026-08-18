function Get-Collector_Exchange_AntiSpamPolicies {
    param([Parameter(Mandatory)]$Context)
    $lang = Get-M365TRLanguage -Context $Context
    $description = if ($lang -eq 'en') {
        'Spam filtering policies configured in Exchange Online - full settings and scope (rule linked to each policy).'
    } else {
        'Zasady filtrowania spamu skonfigurowane w Exchange Online - pełne ustawienia oraz zasięg (reguła powiązana z każdą zasadą).'
    }
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-HostedContentFilterPolicy }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Zasady Anti-Spam (Content Filter)' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Zasady Anti-Spam (Content Filter)' -Status 'empty' -Description $description
    }

    $rulesResult = Invoke-M365TREXOCommand -ScriptBlock { Get-HostedContentFilterRule }
    $rules = if ($rulesResult.Success) { @($rulesResult.Data) } else { @() }
    $labelMap = Get-M365TREXOSecurityPolicyLabelMap -Language $lang
    $excludeProps = @(
        'Identity', 'Id', 'Guid', 'DistinguishedName', 'ExchangeVersion', 'ObjectCategory', 'ObjectClass',
        'OrganizationalUnitRoot', 'OriginatingServer', 'IsValid', 'ObjectState', 'RunspaceId',
        'WhenChanged', 'WhenChangedUTC', 'WhenCreated', 'WhenCreatedUTC', 'ImmutableId',
        'Name', 'IsDefault', 'PSComputerName', 'PSShowComputerName',
        'ObjectVersion', 'CreatedBy', 'LastModifiedBy', 'ReadOnly', 'DistributionStatus',
        'DistributionSyncStatus', 'ModificationTimeUtc', 'CreationTimeUtc',
        'DirectoryObjectVersion', 'ExchangeObjectId', 'OrganizationId', 'RecommendedPolicyType'
    )

    $records = $r.Data | ForEach-Object {
        $policyName = $_.Name
        $basicRows = @(
            [PSCustomObject]@{ 'Ustawienie' = if ($lang -eq 'en') { 'Default policy' } else { 'Zasada domyślna' }; 'Wartość' = "$($_.IsDefault)" }
        )
        $settingsRows = @(ConvertTo-M365TRLabeledRows -InputObject $_ -LabelMap $labelMap -ExcludeProperties $excludeProps -Language $lang)
        $rule = $rules | Where-Object { $_.HostedContentFilterPolicy -eq $policyName } | Select-Object -First 1
        $assignRows = @(Get-M365TREXORuleAssignmentRows -Rule $rule -Language $lang)

        New-M365TRDetailRecord -Name $policyName -Tables @(
            (New-M365TRDetailTable -Title 'Podstawowe' -Rows $basicRows)
            (New-M365TRDetailTable -Title 'Ustawienia' -Rows $settingsRows)
            (New-M365TRDetailTable -Title 'Przypisania' -Rows $assignRows)
        )
    }

    New-M365TRCollectorResult -Component 'Exchange' -Section 'Zasady Anti-Spam (Content Filter)' `
        -Description $description -Status 'ok' -Records -Data $records
}
