function Get-M365TRGenericSettingsSummary {
    <#
    .SYNOPSIS
    Best-effort fallback for policy/profile types too heterogeneous for a bespoke summary
    (e.g. Intune device configuration profiles - 100+ distinct types with wildly different
    settings). Translates the most common Intune property names into Polish "Etykieta: Wartość"
    pairs instead of a raw property=value dump; unmapped properties fall back to a humanized
    version of their camelCase name so nothing is silently hidden.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$InputObject,
        [string[]]$ExcludeProperties = @(
            'id', '@odata.type', 'displayName', 'description', 'createdDateTime',
            'lastModifiedDateTime', 'version', 'roleScopeTagIds', 'supportsScopeTags'
        ),
        [int]$MaxItems = 10,
        [ValidateSet('pl', 'en')][string]$Language = 'pl'
    )

    # Etykiety i formatowanie wartości - wspólne z pełnymi tabelami szczegółów
    # (Get-M365TRSettingsDetailRows), żeby oba widoki tego samego obiektu się nie rozjeżdżały.
    # Zawsze budowane po polsku, a potem (dla en) tłumaczone fraza-po-frazie przez ten sam słownik
    # co tabele szczegółów - inaczej niż tam, cała ta funkcja zwraca JEDNO złożone zdanie, więc
    # tłumaczenie w miejscu renderowania (dopasowanie całego tekstu 1:1) by tu nie zadzialalo.
    $labelMap = Get-M365TRIntuneLabelMap

    $ignoredValues = @('deviceDefault', 'notConfigured', 'unavailable', 'none', '')
    $notable = $InputObject.PSObject.Properties | Where-Object {
        $_.Name -notin $ExcludeProperties -and $null -ne $_.Value -and $_.Value -isnot [array] -and
        (
            ($_.Value -is [bool]) -or
            ($_.Value -is [int] -and $_.Value -gt 0) -or
            ($_.Value -is [string] -and $_.Value -notin $ignoredValues)
        )
    }

    if (@($notable).Count -eq 0) {
        return $(if ($Language -eq 'en') { '(no configured restrictions/requirements)' } else { '(brak skonfigurowanych ograniczeń/wymagań)' })
    }

    $shown = $notable | Select-Object -First $MaxItems
    $pairs = $shown | ForEach-Object {
        $label = if ($labelMap.ContainsKey($_.Name)) { $labelMap[$_.Name] } else { ConvertTo-M365TRHumanizedName $_.Name }
        $value = Format-M365TRIntuneSettingValue -Name $_.Name -Value $_.Value
        if ($Language -eq 'en') {
            $label = ConvertTo-M365TRLocalizedText -Text $label -Language 'en'
            $value = ConvertTo-M365TRLocalizedText -Text $value -Language 'en'
        }
        "${label}: $value"
    }
    $text = $pairs -join '; '
    $remaining = @($notable).Count - $MaxItems
    if ($remaining -gt 0) {
        $text += $(if ($Language -eq 'en') { " (+$remaining more settings)" } else { " (+$remaining więcej ustawien)" })
    }
    return $text
}
