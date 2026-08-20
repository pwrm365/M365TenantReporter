function Get-M365TREntraIDPermissionGrantConditionSummary {
    param($Condition, [ValidateSet('pl', 'en')][string]$Language = 'pl')
    $parts = New-Object System.Collections.Generic.List[string]
    if ($Language -eq 'en') {
        if ($Condition.permissionType) { $parts.Add("permission type: $($Condition.permissionType)") }
        if ($Condition.permissionClassification -and $Condition.permissionClassification -ne 'all') { $parts.Add("classification: $($Condition.permissionClassification)") }
        if ($Condition.resourceApplication -and $Condition.resourceApplication -ne 'any') { $parts.Add("resource app: $($Condition.resourceApplication)") }
        if ($Condition.clientApplicationIds -and @($Condition.clientApplicationIds) -notcontains 'all') { $parts.Add("client apps: $(@($Condition.clientApplicationIds) -join ', ')") } else { $parts.Add('client apps: any') }
        if ($Condition.clientApplicationsFromVerifiedPublisherOnly) { $parts.Add('verified publisher only') }
        if ($Condition.clientApplicationTenantIds) { $parts.Add("client tenant restriction: $(@($Condition.clientApplicationTenantIds) -join ', ')") }
        if ($parts.Count -eq 0) { return '(no further restriction)' }
    } else {
        if ($Condition.permissionType) { $parts.Add("typ uprawnienia: $($Condition.permissionType)") }
        if ($Condition.permissionClassification -and $Condition.permissionClassification -ne 'all') { $parts.Add("klasyfikacja: $($Condition.permissionClassification)") }
        if ($Condition.resourceApplication -and $Condition.resourceApplication -ne 'any') { $parts.Add("aplikacja zasobowa: $($Condition.resourceApplication)") }
        if ($Condition.clientApplicationIds -and @($Condition.clientApplicationIds) -notcontains 'all') { $parts.Add("aplikacje klienckie: $(@($Condition.clientApplicationIds) -join ', ')") } else { $parts.Add('aplikacje klienckie: dowolne') }
        if ($Condition.clientApplicationsFromVerifiedPublisherOnly) { $parts.Add('tylko zweryfikowany wydawca') }
        if ($Condition.clientApplicationTenantIds) { $parts.Add("ograniczenie tenanta aplikacji: $(@($Condition.clientApplicationTenantIds) -join ', ')") }
        if ($parts.Count -eq 0) { return '(brak dodatkowych ograniczeń)' }
    }
    return ($parts -join '; ')
}

function Get-Collector_EntraID_PermissionGrantPolicies {
    <#
    .SYNOPSIS
    Zasady zgody (Permission Grant Policies) - warunki, na jakich zwykli użytkownicy lub
    administratorzy mogą przyznawać zgodę aplikacjom na uprawnienia. Sam fakt istnienia
    niestandardowej (nie-wbudowanej) zasady jest wart odnotowania - który uzytkownik/aplikacja
    ma taka zgode widac w sekcji "Zgoda na aplikacje (App Consent)".
    #>
    param([Parameter(Mandatory)]$Context)
    $lang = Get-M365TRLanguage -Context $Context

    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/policies/permissionGrantPolicies'
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Zasady zgody (Permission Grant Policies)' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Zasady zgody (Permission Grant Policies)' -Status 'empty' `
            -Description 'Zasady zgody (Permission Grant Policies) definiujące warunki przyznawania zgody aplikacjom.'
    }

    $records = $r.Data | ForEach-Object {
        $policy = $_
        $isBuiltIn = "$($policy.id)" -like 'microsoft-*'
        $basicRows = @(
            [PSCustomObject]@{ 'Ustawienie' = 'Identyfikator'; 'Wartość' = "$($policy.id)" }
            [PSCustomObject]@{ 'Ustawienie' = 'Wbudowana (dostarczona przez Microsoft)'; 'Wartość' = if ($isBuiltIn) { 'Tak' } else { 'Nie' } }
            [PSCustomObject]@{ 'Ustawienie' = 'Opis'; 'Wartość' = "$($policy.description)" }
        )

        $includesResult = Invoke-M365TRGraphRequest -Context $Context -Path "/policies/permissionGrantPolicies/$($policy.id)/includes"
        $excludesResult = Invoke-M365TRGraphRequest -Context $Context -Path "/policies/permissionGrantPolicies/$($policy.id)/excludes"
        $conditionRows = New-Object System.Collections.Generic.List[object]
        if ($includesResult.Success) {
            foreach ($cond in $includesResult.Data) {
                $label = if ($lang -eq 'en') { 'Includes' } else { 'Dołącza' }
                $conditionRows.Add([PSCustomObject]@{ 'Ustawienie' = $label; 'Wartość' = (Get-M365TREntraIDPermissionGrantConditionSummary -Condition $cond -Language $lang) })
            }
        }
        if ($excludesResult.Success) {
            foreach ($cond in $excludesResult.Data) {
                $label = if ($lang -eq 'en') { 'Excludes' } else { 'Wyklucza' }
                $conditionRows.Add([PSCustomObject]@{ 'Ustawienie' = $label; 'Wartość' = (Get-M365TREntraIDPermissionGrantConditionSummary -Condition $cond -Language $lang) })
            }
        }
        if ($conditionRows.Count -eq 0) {
            $conditionRows.Add([PSCustomObject]@{
                'Ustawienie' = if ($lang -eq 'en') { 'Conditions' } else { 'Warunki' }
                'Wartość'    = if ($lang -eq 'en') { '(no conditions defined)' } else { '(brak zdefiniowanych warunków)' }
            })
        }

        $recordName = if ($policy.displayName) { $policy.displayName } else { $policy.id }
        New-M365TRDetailRecord -Name $recordName -Tables @(
            (New-M365TRDetailTable -Title 'Podstawowe' -Rows $basicRows)
            (New-M365TRDetailTable -Title 'Warunki' -Rows $conditionRows)
        )
    }

    New-M365TRCollectorResult -Component 'EntraID' -Section 'Zasady zgody (Permission Grant Policies)' `
        -Description 'Zasady zgody (Permission Grant Policies) definiujące warunki, na jakich użytkownicy lub administratorzy mogą przyznawać aplikacjom zgodę na uprawnienia.' `
        -Status 'ok' -Records -Data $records
}
