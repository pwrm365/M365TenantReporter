function Get-Collector_Exchange_TenantAllowBlockLists {
    <#
    .SYNOPSIS
    Ręcznie dodane wpisy na tenantowej liście dozwolonych/zablokowanych (Tenant Allow/Block List)
    w Microsoft Defender for Office 365 - nadawcy, adresy URL i skróty plików (hash) jawnie
    dopuszczone lub zablokowane niezależnie od standardowego filtrowania.
    #>
    param([Parameter(Mandatory)]$Context)

    $typeLabels = @{ Sender = 'Nadawca'; Url = 'Adres URL'; FileHash = 'Skrót pliku (hash)' }
    $actionLabels = @{ Allow = 'Dozwolone'; Block = 'Zablokowane' }
    $allRows = New-Object System.Collections.Generic.List[object]
    foreach ($listType in @('Sender', 'Url', 'FileHash')) {
        # -ErrorAction Stop: gdy dany typ listy nigdy nie byl uzywany w tenancie, cmdlet potrafi
        # zglosic nieterminalny blad ("Value cannot be null: exchangeConfigUnit") zamiast po prostu
        # zwrocic pusty wynik - bez Stop uciekalby on obok try/catch w Invoke-M365TREXOCommand
        # prosto na konsole. Traktujemy taki blad jak "brak wpisow tego typu", nie jak realny blad.
        $r = Invoke-M365TREXOCommand -ScriptBlock { Get-TenantAllowBlockListItems -ListType $listType -ErrorAction Stop }
        if (-not $r.Success) { continue }
        foreach ($item in $r.Data) {
            $value = if ($item.Value) { "$($item.Value)" } elseif ($item.Entry) { "$($item.Entry)" } else { "$($item.SenderDomainIs)" }
            $expires = if ($item.ExpirationDate) { ([datetime]$item.ExpirationDate).ToString('dd.MM.yyyy') } else { 'Nie wygasa' }
            $action = if ($actionLabels.ContainsKey("$($item.Action)")) { $actionLabels["$($item.Action)"] } else { "$($item.Action)" }
            $allRows.Add([PSCustomObject]@{
                'Typ listy' = $typeLabels[$listType]
                'Wartość'   = $value
                'Akcja'     = $action
                'Wygasa'    = $expires
                'Uwagi'     = $item.Notes
            })
        }
    }

    if ($allRows.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Tenant Allow/Block List' -Status 'empty' `
            -Description 'Ręcznie dodane wpisy dozwolone/zablokowane (nadawcy, URL, skróty plików) w Microsoft Defender for Office 365.'
    }

    New-M365TRCollectorResult -Component 'Exchange' -Section 'Tenant Allow/Block List' `
        -Description 'Ręcznie dodane wpisy na tenantowej liście dozwolonych/zablokowanych (nadawcy, adresy URL, skróty plików) w Microsoft Defender for Office 365 - nadpisują standardowe filtrowanie.' `
        -Status 'ok' -Data $allRows
}
