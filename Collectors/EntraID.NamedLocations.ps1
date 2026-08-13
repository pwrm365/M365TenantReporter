function Get-Collector_EntraID_NamedLocations {
    <#
    .SYNOPSIS
    Nazwane lokalizacje (Named Locations) - zakresy IP i kraje przywolywane przez polityki
    Conditional Access. Rozwiazuje surowe zakresy/kraje do czytelnej listy zamiast samych GUID-ow.
    #>
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/identity/conditionalAccess/namedLocations'
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Nazwane lokalizacje (Named Locations)' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Nazwane lokalizacje (Named Locations)' -Status 'empty' `
            -Description 'Nazwane lokalizacje (zakresy IP, kraje) wykorzystywane w politykach Conditional Access.'
    }

    $rows = foreach ($loc in $r.Data) {
        $typ = ($loc.'@odata.type' -replace '#microsoft.graph\.', '')
        $szczegoly = if ($typ -eq 'ipNamedLocation') {
            $ranges = @($loc.ipRanges | ForEach-Object { $_.cidrAddress })
            $count = $ranges.Count
            $shown = ($ranges | Select-Object -First 8) -join ', '
            if ($count -gt 8) { $shown += " (+$($count - 8) więcej)" }
            $shown
        } elseif ($typ -eq 'countryNamedLocation') {
            ($loc.countriesAndRegions -join ', ')
        } else { '' }

        [PSCustomObject]@{
            'Nazwa'             = $loc.displayName
            'Typ'               = if ($typ -eq 'ipNamedLocation') { 'Zakres IP' } elseif ($typ -eq 'countryNamedLocation') { 'Kraje/regiony' } else { $typ }
            'Zaufana'           = if ($typ -eq 'ipNamedLocation') { if ($loc.isTrusted) { 'Tak' } else { 'Nie' } } else { '-' }
            'Szczegóły'         = $szczegoly
        }
    }
    $rows = @($rows)

    New-M365TRCollectorResult -Component 'EntraID' -Section 'Nazwane lokalizacje (Named Locations)' `
        -Description 'Nazwane lokalizacje (zakresy IP, kraje) wykorzystywane w politykach Conditional Access.' `
        -Status 'ok' -Data $rows
}
