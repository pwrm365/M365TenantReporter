function Get-M365TRRetentionLabelSummary {
    param($Label, [ValidateSet('pl', 'en')][string]$Language = 'pl')
    $parts = New-Object System.Collections.Generic.List[string]

    if ($Language -eq 'en') {
        $actionText = switch ($Label.RetentionAction) {
            'Keep'           { 'Retain' }
            'Delete'         { 'Delete' }
            'KeepAndDelete'  { 'Retain and delete' }
            default          { [string]$Label.RetentionAction }
        }
        $durationText = $null
        if ($Label.RetentionDuration) {
            $durationRaw = $Label.RetentionDuration
            $durationInt = $durationRaw -as [int]
            if ($null -ne $durationInt -and $durationInt -ge 365) {
                $years = [math]::Round($durationInt / 365, 1)
                $durationText = "after $durationInt days (~$years years)"
            } elseif ($null -ne $durationInt) {
                $durationText = "after $durationInt days"
            } else {
                $durationText = "after period: $durationRaw"
            }
        }
        if ($actionText -and $durationText) {
            $ageBasis = switch ($Label.RetentionType) {
                'ModificationAgeInDays' { 'from last modification' }
                'CreationAgeInDays'     { 'from creation' }
                'EventAgeInDays'        { 'from event' }
                default                 { $null }
            }
            $sentence = "$actionText $durationText"
            if ($ageBasis) { $sentence += " $ageBasis" }
            $parts.Add($sentence)
        } elseif ($actionText) {
            $parts.Add($actionText)
        }
        if ($Label.IsRecordLabel -eq $true) { $parts.Add('marked as a record') }
        if ($parts.Count -eq 0) { return '(no key settings to summarize)' }
    } else {
        $actionText = switch ($Label.RetentionAction) {
            'Keep'           { 'Zachowaj' }
            'Delete'         { 'Usuń' }
            'KeepAndDelete'  { 'Zachowaj i usuń' }
            default          { [string]$Label.RetentionAction }
        }
        $durationText = $null
        if ($Label.RetentionDuration) {
            $durationRaw = $Label.RetentionDuration
            $durationInt = $durationRaw -as [int]
            if ($null -ne $durationInt -and $durationInt -ge 365) {
                $years = [math]::Round($durationInt / 365, 1)
                $durationText = "po $durationInt dni (~$years lat)"
            } elseif ($null -ne $durationInt) {
                $durationText = "po $durationInt dni"
            } else {
                $durationText = "po okresie: $durationRaw"
            }
        }
        if ($actionText -and $durationText) {
            $ageBasis = switch ($Label.RetentionType) {
                'ModificationAgeInDays' { 'od modyfikacji' }
                'CreationAgeInDays'     { 'od utworzenia' }
                'EventAgeInDays'        { 'od zdarzenia' }
                default                 { $null }
            }
            $sentence = "$actionText $durationText"
            if ($ageBasis) { $sentence += " $ageBasis" }
            $parts.Add($sentence)
        } elseif ($actionText) {
            $parts.Add($actionText)
        }
        if ($Label.IsRecordLabel -eq $true) { $parts.Add('oznaczona jako rekord') }
        if ($parts.Count -eq 0) { return '(brak kluczowych ustawien do podsumowania)' }
    }
    return ($parts -join '; ')
}

function Get-Collector_Purview_RetentionLabels {
    param([Parameter(Mandatory)]$Context)
    $lang = Get-M365TRLanguage -Context $Context
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-ComplianceTag }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Purview' -Section 'Etykiety retencji' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Purview' -Section 'Etykiety retencji' -Status 'empty' `
            -Description 'Etykiety retencji skonfigurowane w Microsoft Purview.'
    }
    $flat = $r.Data | ForEach-Object {
        [PSCustomObject]@{
            'Nazwa'   = $_.Name
            'Co robi' = Get-M365TRRetentionLabelSummary -Label $_ -Language $lang
        }
    }
    New-M365TRCollectorResult -Component 'Purview' -Section 'Etykiety retencji' `
        -Description 'Etykiety retencji skonfigurowane w Microsoft Purview.' -Status 'ok' -Data $flat
}
