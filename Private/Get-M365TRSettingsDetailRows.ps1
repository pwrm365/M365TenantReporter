function Get-M365TRSettingsDetailRows {
    <#
    .SYNOPSIS
    Full, uncapped "Ustawienie / Wartość" row set for one Intune policy/profile object - the
    detail-table counterpart to Get-M365TRGenericSettingsSummary's capped one-line summary.
    Every non-null, non-default property becomes its own row (curated Polish label when known,
    humanized camelCase name otherwise) so a reviewer can see every configured setting, not just
    the first 10.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$InputObject,
        [hashtable]$ExtraLabelMap = @{},
        [string[]]$ExcludeProperties = @(
            'id', '@odata.type', 'displayName', 'description', 'createdDateTime',
            'lastModifiedDateTime', 'version', 'roleScopeTagIds', 'supportsScopeTags'
        )
    )

    $labelMap = Get-M365TRIntuneLabelMap
    foreach ($k in $ExtraLabelMap.Keys) { $labelMap[$k] = $ExtraLabelMap[$k] }

    $ignoredValues = @('deviceDefault', 'notConfigured', 'unavailable', 'none', '')
    $props = $InputObject.PSObject.Properties | Where-Object {
        $_.Name -notin $ExcludeProperties -and $null -ne $_.Value -and $_.Value -isnot [array] -and
        $_.Value -isnot [PSCustomObject] -and
        (
            ($_.Value -is [bool]) -or
            ($_.Value -is [int] -and $_.Value -ne 0) -or
            ($_.Value -is [string] -and $_.Value -notin $ignoredValues)
        )
    }

    foreach ($p in $props) {
        $label = if ($labelMap.ContainsKey($p.Name)) { $labelMap[$p.Name] } else { ConvertTo-M365TRHumanizedName $p.Name }
        $value = Format-M365TRIntuneSettingValue -Name $p.Name -Value $p.Value
        [PSCustomObject]@{ 'Ustawienie' = $label; 'Wartość' = $value }
    }
}
