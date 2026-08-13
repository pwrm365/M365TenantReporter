function Get-M365TRDlpRuleSummary {
    param($Rule)
    $parts = New-Object System.Collections.Generic.List[string]

    $sitNames = New-Object System.Collections.Generic.List[string]
    foreach ($sit in @($Rule.ContentContainsSensitiveInformation)) {
        if ($sit -is [hashtable] -and $sit.ContainsKey('name')) { $sitNames.Add([string]$sit['name']) }
        elseif ($sit.name) { $sitNames.Add([string]$sit.name) }
    }
    if ($sitNames.Count -gt 0) { $parts.Add("wykrywa: $($sitNames -join ', ')") }

    if ($Rule.BlockAccess -eq $true) { $parts.Add('BLOKUJE dostęp/wysylke') }
    if (@($Rule.NotifyUser).Count -gt 0) { $parts.Add("powiadamia: $(@($Rule.NotifyUser) -join ', ')") }
    if (@($Rule.GenerateIncidentReport).Count -gt 0) { $parts.Add("raportuje incydent do: $(@($Rule.GenerateIncidentReport) -join ', ')") }

    if ($parts.Count -eq 0) { return '(brak szczegolowych akcji do podsumowania)' }
    return ($parts -join '; ')
}

function Get-Collector_Purview_DlpCompliancePolicies {
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-DlpCompliancePolicy }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Purview' -Section 'Zasady DLP (Data Loss Prevention)' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Purview' -Section 'Zasady DLP (Data Loss Prevention)' -Status 'empty' `
            -Description 'Zasady zapobiegania utracie danych (DLP) skonfigurowane w Microsoft Purview.'
    }
    $flat = $r.Data | ForEach-Object {
        $policyName = $_.Name
        $rulesResult = Invoke-M365TREXOCommand -ScriptBlock { Get-DlpComplianceRule -Policy $policyName }
        $ruleSummaries = if ($rulesResult.Success -and $rulesResult.Data.Count -gt 0) {
            ($rulesResult.Data | ForEach-Object { "[$($_.Name)] $(Get-M365TRDlpRuleSummary -Rule $_)" }) -join ' | '
        } else { '(brak zdefiniowanych regul)' }
        [PSCustomObject]@{
            'Nazwa'    = $policyName
            'Włączony' = $_.Mode
            'Co robi'  = $ruleSummaries
        }
    }
    New-M365TRCollectorResult -Component 'Purview' -Section 'Zasady DLP (Data Loss Prevention)' `
        -Description 'Zasady zapobiegania utracie danych (DLP) skonfigurowane w Microsoft Purview.' -Status 'ok' -Data $flat
}
