function Get-M365TRDlpRuleDetailRows {
    param($Rule, [ValidateSet('pl', 'en')][string]$Language = 'pl')
    $rows = New-Object System.Collections.Generic.List[object]

    $sitNames = New-Object System.Collections.Generic.List[string]
    foreach ($sit in @($Rule.ContentContainsSensitiveInformation)) {
        if ($sit -is [hashtable] -and $sit.ContainsKey('name')) { $sitNames.Add([string]$sit['name']) }
        elseif ($sit.name) { $sitNames.Add([string]$sit.name) }
    }

    if ($Language -eq 'en') {
        $rows.Add([PSCustomObject]@{ 'Ustawienie' = 'Rule state'; 'Wartość' = if ($Rule.Disabled) { 'Disabled' } else { 'Enabled' } })
        if ($sitNames.Count -gt 0) { $rows.Add([PSCustomObject]@{ 'Ustawienie' = 'Detects sensitive info type'; 'Wartość' = ($sitNames -join ', ') }) }
        if ($Rule.ContentContainsSensitiveInformation -and @($Rule.ContentContainsSensitiveInformation).Count -gt 0 -and $Rule.MinCount) {
            $rows.Add([PSCustomObject]@{ 'Ustawienie' = 'Minimum instance count'; 'Wartość' = "$($Rule.MinCount)" })
        }
        if ($Rule.BlockAccess -eq $true) { $rows.Add([PSCustomObject]@{ 'Ustawienie' = 'Action: block access/sending'; 'Wartość' = 'Yes' }) }
        if ($Rule.BlockAccessScope) { $rows.Add([PSCustomObject]@{ 'Ustawienie' = 'Block scope'; 'Wartość' = "$($Rule.BlockAccessScope)" }) }
        if (@($Rule.NotifyUser).Count -gt 0) { $rows.Add([PSCustomObject]@{ 'Ustawienie' = 'Action: notify'; 'Wartość' = (@($Rule.NotifyUser) -join ', ') }) }
        if ($Rule.NotifyPolicyTipCustomText) { $rows.Add([PSCustomObject]@{ 'Ustawienie' = 'Policy tip text'; 'Wartość' = "$($Rule.NotifyPolicyTipCustomText)" }) }
        if (@($Rule.GenerateIncidentReport).Count -gt 0) { $rows.Add([PSCustomObject]@{ 'Ustawienie' = 'Action: send incident report to'; 'Wartość' = (@($Rule.GenerateIncidentReport) -join ', ') }) }
        if ($Rule.IncidentReportContent) { $rows.Add([PSCustomObject]@{ 'Ustawienie' = 'Incident report content'; 'Wartość' = (@($Rule.IncidentReportContent) -join ', ') }) }
        if ($Rule.ReportSeverityLevel) { $rows.Add([PSCustomObject]@{ 'Ustawienie' = 'Reported severity'; 'Wartość' = "$($Rule.ReportSeverityLevel)" }) }
        if ($Rule.StopPolicyProcessing -eq $true) { $rows.Add([PSCustomObject]@{ 'Ustawienie' = 'Stop processing further rules'; 'Wartość' = 'Yes' }) }
        if (@($Rule.AccessScope).Count -gt 0) { $rows.Add([PSCustomObject]@{ 'Ustawienie' = 'Applies to access scope'; 'Wartość' = (@($Rule.AccessScope) -join ', ') }) }
    } else {
        $rows.Add([PSCustomObject]@{ 'Ustawienie' = 'Stan reguły'; 'Wartość' = if ($Rule.Disabled) { 'Wyłączona' } else { 'Włączona' } })
        if ($sitNames.Count -gt 0) { $rows.Add([PSCustomObject]@{ 'Ustawienie' = 'Wykrywa typ danych wrażliwych'; 'Wartość' = ($sitNames -join ', ') }) }
        if ($Rule.ContentContainsSensitiveInformation -and @($Rule.ContentContainsSensitiveInformation).Count -gt 0 -and $Rule.MinCount) {
            $rows.Add([PSCustomObject]@{ 'Ustawienie' = 'Minimalna liczba wystąpień'; 'Wartość' = "$($Rule.MinCount)" })
        }
        if ($Rule.BlockAccess -eq $true) { $rows.Add([PSCustomObject]@{ 'Ustawienie' = 'Akcja: blokuj dostęp/wysyłkę'; 'Wartość' = 'Tak' }) }
        if ($Rule.BlockAccessScope) { $rows.Add([PSCustomObject]@{ 'Ustawienie' = 'Zasięg blokady'; 'Wartość' = "$($Rule.BlockAccessScope)" }) }
        if (@($Rule.NotifyUser).Count -gt 0) { $rows.Add([PSCustomObject]@{ 'Ustawienie' = 'Akcja: powiadom'; 'Wartość' = (@($Rule.NotifyUser) -join ', ') }) }
        if ($Rule.NotifyPolicyTipCustomText) { $rows.Add([PSCustomObject]@{ 'Ustawienie' = 'Treść wskazówki (policy tip)'; 'Wartość' = "$($Rule.NotifyPolicyTipCustomText)" }) }
        if (@($Rule.GenerateIncidentReport).Count -gt 0) { $rows.Add([PSCustomObject]@{ 'Ustawienie' = 'Akcja: wyślij raport o incydencie do'; 'Wartość' = (@($Rule.GenerateIncidentReport) -join ', ') }) }
        if ($Rule.IncidentReportContent) { $rows.Add([PSCustomObject]@{ 'Ustawienie' = 'Zawartość raportu incydentu'; 'Wartość' = (@($Rule.IncidentReportContent) -join ', ') }) }
        if ($Rule.ReportSeverityLevel) { $rows.Add([PSCustomObject]@{ 'Ustawienie' = 'Zgłaszana istotność'; 'Wartość' = "$($Rule.ReportSeverityLevel)" }) }
        if ($Rule.StopPolicyProcessing -eq $true) { $rows.Add([PSCustomObject]@{ 'Ustawienie' = 'Zatrzymaj przetwarzanie kolejnych reguł'; 'Wartość' = 'Tak' }) }
        if (@($Rule.AccessScope).Count -gt 0) { $rows.Add([PSCustomObject]@{ 'Ustawienie' = 'Dotyczy zasięgu dostępu'; 'Wartość' = (@($Rule.AccessScope) -join ', ') }) }
    }
    return $rows
}

function Get-Collector_Purview_DlpCompliancePolicies {
    param([Parameter(Mandatory)]$Context)
    $lang = Get-M365TRLanguage -Context $Context
    $description = if ($lang -eq 'en') {
        'Data Loss Prevention (DLP) policies configured in Microsoft Purview - locations, mode, and each rule''s detection conditions and actions.'
    } else {
        'Zasady zapobiegania utracie danych (DLP) skonfigurowane w Microsoft Purview - lokalizacje, tryb oraz reguły wykrywania i akcje.'
    }
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-DlpCompliancePolicy }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Purview' -Section 'Zasady DLP (Data Loss Prevention)' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Purview' -Section 'Zasady DLP (Data Loss Prevention)' -Status 'empty' -Description $description
    }

    $locationLabelMap = if ($lang -eq 'en') {
        @{
            Mode                          = 'Mode'
            Priority                      = 'Priority'
            Comment                       = 'Admin comment'
            ExchangeLocation              = 'Exchange (included)'
            ExchangeLocationException     = 'Exchange (excluded)'
            SharePointLocation            = 'SharePoint (included)'
            SharePointLocationException   = 'SharePoint (excluded)'
            OneDriveLocation              = 'OneDrive (included)'
            OneDriveLocationException     = 'OneDrive (excluded)'
            TeamsLocation                 = 'Teams (included)'
            TeamsLocationException        = 'Teams (excluded)'
            EndpointDlpLocation           = 'Devices - endpoint DLP (included)'
            EndpointDlpLocationException  = 'Devices - endpoint DLP (excluded)'
            OnPremisesScannerDlpLocation  = 'On-premises scanner (included)'
            ThirdPartyAppDlpLocation      = 'Third-party apps / connected apps'
            Workload                      = 'Workload'
            Type                          = 'Policy type'
        }
    } else {
        @{
            Mode                          = 'Tryb'
            Priority                      = 'Priorytet'
            Comment                       = 'Komentarz administratora'
            ExchangeLocation              = 'Exchange (objęte)'
            ExchangeLocationException     = 'Exchange (wykluczone)'
            SharePointLocation            = 'SharePoint (objęte)'
            SharePointLocationException   = 'SharePoint (wykluczone)'
            OneDriveLocation              = 'OneDrive (objęte)'
            OneDriveLocationException     = 'OneDrive (wykluczone)'
            TeamsLocation                 = 'Teams (objęte)'
            TeamsLocationException        = 'Teams (wykluczone)'
            EndpointDlpLocation           = 'Urządzenia - endpoint DLP (objęte)'
            EndpointDlpLocationException  = 'Urządzenia - endpoint DLP (wykluczone)'
            OnPremisesScannerDlpLocation  = 'Skaner lokalny (objęte)'
            ThirdPartyAppDlpLocation      = 'Aplikacje firm trzecich / połączone'
            Workload                      = 'Obszar roboczy'
            Type                          = 'Typ zasady'
        }
    }
    $excludeProps = @(
        'Identity', 'Id', 'Guid', 'DistinguishedName', 'ExchangeVersion', 'ObjectCategory', 'ObjectClass',
        'OrganizationalUnitRoot', 'OriginatingServer', 'IsValid', 'ObjectState', 'RunspaceId',
        'WhenChanged', 'WhenChangedUTC', 'WhenCreated', 'WhenCreatedUTC', 'ImmutableId',
        'Name', 'Mode', 'PSComputerName', 'PSShowComputerName',
        'PolicyRulesMetaData', 'PolicyConstraints', 'ObjectVersion', 'CreatedBy', 'LastModifiedBy',
        'ReadOnly', 'DistributionStatus', 'DistributionSyncStatus', 'ModificationTimeUtc', 'CreationTimeUtc',
        'DirectoryObjectVersion', 'ExchangeObjectId', 'OrganizationId', 'PolicyCategory',
        'IsSimulationPolicy', 'IsColdDataSimulationPolicy', 'ExpectedLocations', 'CompletedLocations',
        'FailedLocations', 'ForceValidate', 'GlobalListType', 'Locations', 'Summary'
    )

    $noRulesLabel = if ($lang -eq 'en') { 'Rules' } else { 'Reguły' }
    $noRulesText = if ($lang -eq 'en') { '(no rules defined)' } else { '(brak zdefiniowanych regul)' }
    $rulePrefix = if ($lang -eq 'en') { 'Rule: ' } else { 'Reguła: ' }

    $records = $r.Data | ForEach-Object {
        $policyName = $_.Name
        $basicRows = New-Object System.Collections.Generic.List[object]
        if ($lang -eq 'en') {
            $basicRows.Add([PSCustomObject]@{ 'Ustawienie' = 'Mode'; 'Wartość' = "$($_.Mode)" })
        } else {
            $basicRows.Add([PSCustomObject]@{ 'Ustawienie' = 'Tryb'; 'Wartość' = "$($_.Mode)" })
        }

        $settingsRows = @(ConvertTo-M365TRLabeledRows -InputObject $_ -LabelMap $locationLabelMap -ExcludeProperties $excludeProps -Language $lang)

        $rulesResult = Invoke-M365TREXOCommand -ScriptBlock { Get-DlpComplianceRule -Policy $policyName }
        $tables = New-Object System.Collections.Generic.List[object]
        $tables.Add((New-M365TRDetailTable -Title 'Podstawowe' -Rows $basicRows))
        $tables.Add((New-M365TRDetailTable -Title 'Ustawienia' -Rows $settingsRows))
        if ($rulesResult.Success -and $rulesResult.Data.Count -gt 0) {
            foreach ($rule in $rulesResult.Data) {
                $tables.Add((New-M365TRDetailTable -Title "$rulePrefix$($rule.Name)" -Rows (Get-M365TRDlpRuleDetailRows -Rule $rule -Language $lang)))
            }
        } else {
            $tables.Add((New-M365TRDetailTable -Title $noRulesLabel -Rows @([PSCustomObject]@{ 'Ustawienie' = $noRulesLabel; 'Wartość' = $noRulesText })))
        }

        New-M365TRDetailRecord -Name $policyName -Tables $tables
    }

    New-M365TRCollectorResult -Component 'Purview' -Section 'Zasady DLP (Data Loss Prevention)' `
        -Description $description -Status 'ok' -Records -Data $records
}
