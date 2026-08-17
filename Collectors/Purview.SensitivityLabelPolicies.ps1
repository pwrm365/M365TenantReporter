function ConvertTo-M365TRLabelPolicySettingsMap {
    <#
    .SYNOPSIS
    Get-LabelPolicy zwraca Settings jako tablicę stringów w formacie "[klucz, wartość]" zamiast
    normalnego obiektu - parsujemy to na zwykłą mapę klucz->wartość.
    #>
    param([object[]]$SettingsArray)
    $map = @{}
    foreach ($s in @($SettingsArray)) {
        if ("$s" -match '^\[([^,]+),\s*(.*)\]$') { $map[$matches[1]] = $matches[2] }
    }
    return $map
}

function Get-M365TRLabelPolicySummary {
    param($Policy, [hashtable]$LabelNamesById = @{}, [ValidateSet('pl', 'en')][string]$Language = 'pl')
    $parts = New-Object System.Collections.Generic.List[string]
    $settings = ConvertTo-M365TRLabelPolicySettingsMap -SettingsArray $Policy.Settings

    if ($Language -eq 'en') {
        if (@($Policy.Labels).Count -gt 0) {
            $parts.Add("publishes labels: $((@($Policy.Labels) | ForEach-Object { [string]$_ }) -join ', ')")
        }
        if ($settings.ContainsKey('defaultlabelid') -and $settings['defaultlabelid']) {
            $defaultId = $settings['defaultlabelid']
            $defaultName = if ($LabelNamesById.ContainsKey($defaultId)) { $LabelNamesById[$defaultId] } else { $defaultId }
            $parts.Add("default label for new files/messages: $defaultName")
        }
        if ($settings['mandatory'] -eq 'true') { $parts.Add('labeling mandatory in Office') }
        if ($settings['requiredowngradejustification'] -eq 'true') { $parts.Add('justification required when downgrading/removing a label') }
        if ($settings['powerbimandatory'] -eq 'true') { $parts.Add('labeling mandatory in Power BI') }
        if ($settings['teamworkmandatory'] -eq 'true') { $parts.Add('labeling mandatory in Teams/groups') }
        if ($settings['disablemandatoryinoutlook'] -eq 'true') { $parts.Add('mandatory labeling disabled in Outlook') }
        if ($null -ne $Policy.Priority) { $parts.Add("priority: $($Policy.Priority)") }
        if ($parts.Count -eq 0) { return '(no key settings to summarize)' }
    } else {
        if (@($Policy.Labels).Count -gt 0) {
            $parts.Add("Publikuje etykiety: $((@($Policy.Labels) | ForEach-Object { [string]$_ }) -join ', ')")
        }
        if ($settings.ContainsKey('defaultlabelid') -and $settings['defaultlabelid']) {
            $defaultId = $settings['defaultlabelid']
            $defaultName = if ($LabelNamesById.ContainsKey($defaultId)) { $LabelNamesById[$defaultId] } else { $defaultId }
            $parts.Add("domyślna etykieta dla nowych plików/wiadomości: $defaultName")
        }
        if ($settings['mandatory'] -eq 'true') { $parts.Add('etykietowanie wymagane (mandatory) w Office') }
        if ($settings['requiredowngradejustification'] -eq 'true') { $parts.Add('wymagane uzasadnienie przy obniżeniu/usunięciu etykiety') }
        if ($settings['powerbimandatory'] -eq 'true') { $parts.Add('etykietowanie wymagane w Power BI') }
        if ($settings['teamworkmandatory'] -eq 'true') { $parts.Add('etykietowanie wymagane w Teams/grupach') }
        if ($settings['disablemandatoryinoutlook'] -eq 'true') { $parts.Add('wymóg etykietowania wyłączony w Outlooku') }
        if ($null -ne $Policy.Priority) { $parts.Add("priorytet: $($Policy.Priority)") }
        if ($parts.Count -eq 0) { return '(brak kluczowych ustawień do podsumowania)' }
    }
    return ($parts -join '; ')
}

function Get-Collector_Purview_SensitivityLabelPolicies {
    param([Parameter(Mandatory)]$Context)
    $lang = Get-M365TRLanguage -Context $Context
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-LabelPolicy }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Purview' -Section 'Zasady etykiet poufności (Label Policies)' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Purview' -Section 'Zasady etykiet poufności (Label Policies)' -Status 'empty' `
            -Description 'Zasady publikacji etykiet poufności skonfigurowane w Microsoft Purview.'
    }

    $labelsResult = Invoke-M365TREXOCommand -ScriptBlock { Get-Label }
    $labelNamesById = @{}
    if ($labelsResult.Success) {
        foreach ($lbl in $labelsResult.Data) { $labelNamesById["$($lbl.ImmutableId)"] = $lbl.DisplayName }
    }

    $flat = $r.Data | ForEach-Object {
        [PSCustomObject]@{
            'Nazwa'    = $_.Name
            'Włączona' = $_.Enabled
            'Co robi'  = Get-M365TRLabelPolicySummary -Policy $_ -LabelNamesById $labelNamesById -Language $lang
        }
    }
    New-M365TRCollectorResult -Component 'Purview' -Section 'Zasady etykiet poufności (Label Policies)' `
        -Description 'Zasady publikacji etykiet poufności skonfigurowane w Microsoft Purview - w tym domyślna etykieta i wymóg etykietowania (mandatory), jeśli skonfigurowane.' -Status 'ok' -Data $flat
}
