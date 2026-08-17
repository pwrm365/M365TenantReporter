function Get-Collector_Intune_SecurityBaselines {
    <#
    .SYNOPSIS
    One detailed record per Security Baseline / Endpoint Security intent (Podstawowe/Ustawienia/
    Przypisania) - individual settings resolved via Graph's setting-definition lookup where
    possible (see Get-M365TRIntentSettingLabel for the fallback behavior when it isn't).
    #>
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/deviceManagement/intents' -Beta
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Intune' -Section 'Bazowe konfiguracje zabezpieczeń (Security Baselines)' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Intune' -Section 'Bazowe konfiguracje zabezpieczeń (Security Baselines)' -Status 'empty' `
            -Description 'Bazowe konfiguracje zabezpieczeń (Security Baselines) oraz inne intencje (intents) Intune.'
    }

    $records = foreach ($intent in $r.Data) {
        $basicRows = @(
            [PSCustomObject]@{ Ustawienie = 'Nazwa'; Wartość = $intent.displayName }
            [PSCustomObject]@{ Ustawienie = 'Opis'; Wartość = $intent.description }
            [PSCustomObject]@{ Ustawienie = 'SzablonId'; Wartość = $intent.templateId }
        ) | Where-Object { $_.Wartość }

        $settingsRows = New-Object System.Collections.Generic.List[object]
        try {
            $sr = Invoke-M365TRGraphRequest -Context $Context -Path "/deviceManagement/intents/$($intent.id)/settings" -Beta
            if ($sr.Success) {
                foreach ($s in $sr.Data) {
                    $defId = $s.definitionId
                    if (-not $defId) { continue }
                    $rawVal = if ($null -ne $s.value) { $s.value }
                              elseif ($null -ne $s.valueJson) { ($s.valueJson -replace '^"|"$', '') }
                              else { $null }
                    if ($null -eq $rawVal -or "$rawVal" -eq '') { continue }
                    if ("$rawVal" -eq 'true') { $rawVal = $true } elseif ("$rawVal" -eq 'false') { $rawVal = $false }
                    $label = Get-M365TRIntentSettingLabel -Context $Context -DefinitionId $defId
                    $settingsRows.Add([PSCustomObject]@{ Ustawienie = $label; Wartość = (Format-M365TRIntuneSettingValue -Name $defId -Value $rawVal) })
                }
            }
        } catch {}

        $assignRows = @()
        try {
            $ar = Invoke-M365TRGraphRequest -Context $Context -Path "/deviceManagement/intents/$($intent.id)/assignments" -Beta
            if ($ar.Success) { $assignRows = @(Get-M365TRAssignmentRows -Context $Context -Assignments $ar.Data) }
        } catch {}

        New-M365TRDetailRecord -Name $intent.displayName -Tables @(
            (New-M365TRDetailTable -Title 'Podstawowe' -Rows $basicRows)
            (New-M365TRDetailTable -Title 'Ustawienia' -Rows @($settingsRows))
            (New-M365TRDetailTable -Title 'Przypisania' -Rows $assignRows)
        )
    }

    New-M365TRCollectorResult -Component 'Intune' -Section 'Bazowe konfiguracje zabezpieczeń (Security Baselines)' `
        -Description 'Bazowe konfiguracje zabezpieczeń (Security Baselines) oraz inne intencje (intents) Intune.' -Status 'ok' -Records -Data $records
}
