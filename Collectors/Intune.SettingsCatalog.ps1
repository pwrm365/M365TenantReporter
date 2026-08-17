function Get-Collector_Intune_SettingsCatalog {
    <#
    .SYNOPSIS
    One detailed record per Settings Catalog policy (Podstawowe/Ustawienia/Przypisania) - every
    individual setting resolved to its display name and value where Microsoft Graph's setting
    definition lookup succeeds, falling back to a humanized version of the raw setting ID
    otherwise (best-effort: Settings Catalog's setting space is huge and not every definition is
    guaranteed to resolve, but the raw setting is still shown either way, never silently dropped).
    #>
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/deviceManagement/configurationPolicies'
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Intune' -Section 'Zasady Settings Catalog' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Intune' -Section 'Zasady Settings Catalog' -Status 'empty' `
            -Description 'Zasady oparte na Settings Catalog konfigurujące ustawienia urządzeń.'
    }

    $records = foreach ($p in $r.Data) {
        $basicRows = @(
            [PSCustomObject]@{ Ustawienie = 'Nazwa'; Wartość = $p.name }
            [PSCustomObject]@{ Ustawienie = 'Opis'; Wartość = $p.description }
            [PSCustomObject]@{ Ustawienie = 'Platformy'; Wartość = $p.platforms }
            [PSCustomObject]@{ Ustawienie = 'Technologie'; Wartość = $p.technologies }
            [PSCustomObject]@{ Ustawienie = 'Utworzono'; Wartość = $p.createdDateTime }
            [PSCustomObject]@{ Ustawienie = 'Zmodyfikowano'; Wartość = $p.lastModifiedDateTime }
        ) | Where-Object { $_.Wartość }

        $settingsRows = New-Object System.Collections.Generic.List[object]
        try {
            $sr = Invoke-M365TRGraphRequest -Context $Context -Path "/deviceManagement/configurationPolicies/$($p.id)/settings"
            if ($sr.Success) {
                foreach ($s in $sr.Data) {
                    if (-not $s.settingInstance) { continue }
                    foreach ($row in (ConvertTo-M365TRSettingInstanceRows -Context $Context -Instance $s.settingInstance)) {
                        $settingsRows.Add($row)
                    }
                }
            }
        } catch {}

        $assignRows = @()
        try {
            $ar = Invoke-M365TRGraphRequest -Context $Context -Path "/deviceManagement/configurationPolicies/$($p.id)/assignments"
            if ($ar.Success) { $assignRows = @(Get-M365TRAssignmentRows -Context $Context -Assignments $ar.Data) }
        } catch {}

        New-M365TRDetailRecord -Name $p.name -Tables @(
            (New-M365TRDetailTable -Title 'Podstawowe' -Rows $basicRows)
            (New-M365TRDetailTable -Title 'Ustawienia' -Rows @($settingsRows))
            (New-M365TRDetailTable -Title 'Przypisania' -Rows $assignRows)
        )
    }

    New-M365TRCollectorResult -Component 'Intune' -Section 'Zasady Settings Catalog' `
        -Description 'Zasady oparte na Settings Catalog konfigurujące ustawienia urządzeń.' -Status 'ok' -Records -Data $records
}
