function Get-M365TRLabelActionSummary {
    param($LabelActions)
    if (-not $LabelActions -or @($LabelActions).Count -eq 0) {
        return 'Etykieta opisowa - brak automatycznej ochrony (bez szyfrowania/znaków wodnych).'
    }
    $parts = New-Object System.Collections.Generic.List[string]
    foreach ($raw in @($LabelActions)) {
        try { $action = $raw | ConvertFrom-Json } catch { continue }
        $settingsMap = @{}
        foreach ($s in @($action.Settings)) { $settingsMap[$s.Key] = $s.Value }
        switch ($action.Type) {
            'encrypt' {
                $txt = 'szyfrowanie'
                if ($settingsMap['protectiontype'] -eq 'template') { $txt += ' (szablon uprawnień)' }
                elseif ($settingsMap['promptuser'] -eq 'true') { $txt += ' (użytkownik wybiera uprawnienia)' }
                elseif ($settingsMap['encryptonly'] -eq 'true') { $txt += ' (tylko szyfrowanie, bez ograniczeń uprawnień)' }
                if ($settingsMap['donotforward'] -eq 'true') { $txt += '; opcja "Nie przekazuj dalej"' }
                $parts.Add($txt)
            }
            'metadata' { $parts.Add('dodaje metadane klasyfikacji do pliku') }
            'watermark' { $parts.Add('dodaje znak wodny') }
            'header' { $parts.Add('dodaje naglowek') }
            'footer' { $parts.Add('dodaje stopke') }
            'justify' { $parts.Add('wymaga uzasadnienia przy obniżeniu/usunięciu etykiety') }
            'protectadoc' { $parts.Add('ochrona dokumentu Power BI') }
            default { $parts.Add("akcja: $($action.Type)") }
        }
    }
    return ($parts -join '; ')
}

function Get-Collector_Purview_SensitivityLabels {
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-Label }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Purview' -Section 'Etykiety poufności (Sensitivity Labels)' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Purview' -Section 'Etykiety poufności (Sensitivity Labels)' -Status 'empty' `
            -Description 'Etykiety poufności skonfigurowane w Microsoft Purview.'
    }
    $flat = $r.Data | ForEach-Object {
        [PSCustomObject]@{
            'Nazwa'   = $_.DisplayName
            'Opis'    = $_.Tooltip
            'Co robi' = Get-M365TRLabelActionSummary -LabelActions $_.LabelActions
        }
    }
    New-M365TRCollectorResult -Component 'Purview' -Section 'Etykiety poufności (Sensitivity Labels)' `
        -Description 'Etykiety poufności skonfigurowane w Microsoft Purview.' -Status 'ok' -Data $flat
}
