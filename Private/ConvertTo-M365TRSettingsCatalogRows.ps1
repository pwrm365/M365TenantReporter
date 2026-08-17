function Resolve-M365TRSettingDefinition {
    <#
    .SYNOPSIS
    Resolves a Settings Catalog settingDefinitionId (e.g.
    "device_vendor_msft_policy_config_devicelock_devicepasswordenabled") to its metadata
    (display name, and for choice settings, the display names of its options) via Microsoft
    Graph. Cached per process, since the same handful of settings appear across many policies.
    Best-effort: returns $null on any failure so the caller falls back to a humanized ID.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Context, [Parameter(Mandatory)][string]$DefinitionId)

    if (-not $script:M365TRSettingDefCache) { $script:M365TRSettingDefCache = @{} }
    if ($script:M365TRSettingDefCache.ContainsKey($DefinitionId)) { return $script:M365TRSettingDefCache[$DefinitionId] }

    $result = $null
    try {
        $r = Invoke-M365TRGraphRequest -Context $Context -Path "/deviceManagement/configurationSettings/$DefinitionId"
        if ($r.Success -and $r.Data.Count -gt 0) { $result = $r.Data[0] }
    } catch {}
    $script:M365TRSettingDefCache[$DefinitionId] = $result
    return $result
}

function ConvertTo-M365TRHumanizedSettingId {
    <#
    .SYNOPSIS
    Fallback label when a settingDefinitionId can't be resolved via Graph: strips the common
    "device_vendor_msft_policy_config" prefix noise and title-cases what's left.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Id)

    $skip = @('device', 'vendor', 'msft', 'policy', 'config', 'user')
    $parts = @($Id -split '_' | Where-Object { $_ -and $_ -notin $skip })
    if ($parts.Count -eq 0) { $parts = @($Id -split '_') }
    return (($parts | ForEach-Object { (Get-Culture).TextInfo.ToTitleCase($_) }) -join ' > ')
}

function Get-M365TRSettingLabel {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Context, [Parameter(Mandatory)][string]$DefinitionId)
    $def = Resolve-M365TRSettingDefinition -Context $Context -DefinitionId $DefinitionId
    if ($def -and $def.displayName) { return $def.displayName }
    return ConvertTo-M365TRHumanizedSettingId -Id $DefinitionId
}

function Get-M365TRSettingOptionLabel {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Context, [Parameter(Mandatory)][string]$DefinitionId, [string]$OptionValue)
    if (-not $OptionValue) { return $OptionValue }
    $def = Resolve-M365TRSettingDefinition -Context $Context -DefinitionId $DefinitionId
    if ($def -and $def.options) {
        $match = $def.options | Where-Object { $_.itemId -eq $OptionValue } | Select-Object -First 1
        if ($match -and $match.displayName) { return $match.displayName }
    }
    if ($OptionValue -match '_(\d+)$') { return "Opcja $($Matches[1])" }
    return $OptionValue
}

function Get-M365TRIntentSettingLabel {
    <#
    .SYNOPSIS
    Best-effort display name for a `deviceManagement/intents` (Security Baselines / Endpoint
    Security templates - the older, pre-Settings-Catalog intent API) setting definitionId, via
    Microsoft Graph's beta settingDefinitions lookup. This API has shifted over time and not
    every definitionId resolves; unresolved ones fall back to a humanized version of the ID's
    last segment so the setting is still shown, just with a rougher label.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Context, [Parameter(Mandatory)][string]$DefinitionId)

    if (-not $script:M365TRIntentDefCache) { $script:M365TRIntentDefCache = @{} }
    if ($script:M365TRIntentDefCache.ContainsKey($DefinitionId)) { return $script:M365TRIntentDefCache[$DefinitionId] }

    $label = $null
    try {
        $r = Invoke-M365TRGraphRequest -Context $Context -Path "/deviceManagement/settingDefinitions/$DefinitionId" -Beta
        if ($r.Success -and $r.Data.Count -gt 0 -and $r.Data[0].displayName) { $label = $r.Data[0].displayName }
    } catch {}
    if (-not $label) {
        $tail = ($DefinitionId -split '[_-]') | Select-Object -Last 1
        $label = ConvertTo-M365TRHumanizedName $tail
    }
    $script:M365TRIntentDefCache[$DefinitionId] = $label
    return $label
}

function ConvertTo-M365TRSettingInstanceRows {
    <#
    .SYNOPSIS
    Recursively flattens one Settings Catalog `settingInstance` (and any nested child settings,
    e.g. a choice setting's dependent settings) into "Ustawienie / Wartość" rows. Nested settings
    are prefixed with "> " per depth level so the hierarchy stays visible in a flat table.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Context, [Parameter(Mandatory)]$Instance, [int]$Depth = 0)

    $rows = New-Object System.Collections.Generic.List[object]
    $defId = $Instance.settingDefinitionId
    if (-not $defId) { return $rows }
    $label = Get-M365TRSettingLabel -Context $Context -DefinitionId $defId
    $prefix = if ($Depth -gt 0) { ('› ' * $Depth) } else { '' }
    $type = "$($Instance.'@odata.type')"

    switch -Wildcard ($type) {
        '*GroupSettingCollectionInstance' {
            foreach ($grp in @($Instance.groupSettingCollectionValue)) {
                foreach ($child in @($grp.children)) {
                    foreach ($row in (ConvertTo-M365TRSettingInstanceRows -Context $Context -Instance $child -Depth $Depth)) { $rows.Add($row) }
                }
            }
        }
        '*ChoiceSettingCollectionInstance' {
            foreach ($v in @($Instance.choiceSettingCollectionValue)) {
                $rows.Add([PSCustomObject]@{ Ustawienie = "$prefix$label"; Wartość = (Get-M365TRSettingOptionLabel -Context $Context -DefinitionId $defId -OptionValue $v.value) })
                foreach ($child in @($v.children)) {
                    foreach ($row in (ConvertTo-M365TRSettingInstanceRows -Context $Context -Instance $child -Depth ($Depth + 1))) { $rows.Add($row) }
                }
            }
        }
        '*ChoiceSettingInstance' {
            $rows.Add([PSCustomObject]@{ Ustawienie = "$prefix$label"; Wartość = (Get-M365TRSettingOptionLabel -Context $Context -DefinitionId $defId -OptionValue $Instance.choiceSettingValue.value) })
            foreach ($child in @($Instance.choiceSettingValue.children)) {
                foreach ($row in (ConvertTo-M365TRSettingInstanceRows -Context $Context -Instance $child -Depth ($Depth + 1))) { $rows.Add($row) }
            }
        }
        '*SimpleSettingCollectionInstance' {
            $vals = @($Instance.simpleSettingCollectionValue) | ForEach-Object { "$($_.value)" }
            $rows.Add([PSCustomObject]@{ Ustawienie = "$prefix$label"; Wartość = ($vals -join ', ') })
        }
        '*SimpleSettingInstance' {
            $rows.Add([PSCustomObject]@{ Ustawienie = "$prefix$label"; Wartość = "$($Instance.simpleSettingValue.value)" })
        }
        default {
            $rows.Add([PSCustomObject]@{ Ustawienie = "$prefix$label"; Wartość = '(nieobsługiwany typ ustawienia)' })
        }
    }
    return $rows
}
