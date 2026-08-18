function ConvertTo-M365TRLabeledRows {
    <#
    .SYNOPSIS
    Turns a single settings object (e.g. authorizationPolicy, adminSharePointSettings) into
    "Ustawienie: Wartość" table rows - one row per property, so nothing configured in the
    tenant is silently dropped even if a property has no curated label yet. Properties with a
    curated Polish label use it; everything else falls back to a humanized property name.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$InputObject,
        [hashtable]$LabelMap = @{},
        [hashtable]$ValueLabels = @{},
        [string[]]$ExcludeProperties = @('@odata.context', '@odata.type', 'id'),
        [ValidateSet('pl', 'en')][string]$Language = 'pl'
    )

    $props = $InputObject.PSObject.Properties | Where-Object {
        $_.Name -notin $ExcludeProperties -and $null -ne $_.Value -and "$($_.Value)" -ne ''
    }

    foreach ($p in $props) {
        $name = $p.Name
        $raw = $p.Value
        if ($raw -is [array]) {
            if ($raw.Count -eq 0) { continue }
            if ($raw[0] -is [PSCustomObject] -or $raw[0] -is [hashtable]) { continue }
            $shown = @($raw | Select-Object -First 15)
            $value = $shown -join ', '
            if ($raw.Count -gt 15) {
                $value += if ($Language -eq 'en') { " (+$($raw.Count - 15) more)" } else { " (+$($raw.Count - 15) więcej)" }
            }
        } elseif ($raw -is [PSCustomObject] -or $raw -is [hashtable]) {
            continue
        } else {
            $key = "$raw"
            if ($ValueLabels.ContainsKey($name) -and $ValueLabels[$name].ContainsKey($key)) {
                $value = $ValueLabels[$name][$key]
            } elseif ($raw -is [bool]) {
                $value = if ($raw) { 'Tak' } else { 'Nie' }
            } elseif ($raw -is [string] -and $key -in @('true', 'True', 'false', 'False')) {
                $value = if ($key -match '^true$') { 'Tak' } else { 'Nie' }
            } elseif ($raw -is [string] -and $raw.Length -gt 300) {
                $value = if ($Language -eq 'en') { "(long text - $($raw.Length) characters)" } else { "(długi tekst - $($raw.Length) znaków)" }
            } else {
                $value = $key
            }
        }
        $label = if ($LabelMap.ContainsKey($name)) { $LabelMap[$name] } else { ConvertTo-M365TRHumanizedName $name }
        [PSCustomObject]@{ 'Ustawienie' = $label; 'Wartość' = $value }
    }
}
