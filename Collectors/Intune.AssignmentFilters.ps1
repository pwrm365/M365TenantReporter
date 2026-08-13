function Get-Collector_Intune_AssignmentFilters {
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/deviceManagement/assignmentFilters'
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Intune' -Section 'Filtry przypisań (Assignment Filters)' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Intune' -Section 'Filtry przypisań (Assignment Filters)' -Status 'empty' `
            -Description 'Filtry przypisań (Assignment Filters) używane do zawezania zakresu przypisań zasad.'
    }
    $flat = $r.Data | ForEach-Object {
        [PSCustomObject]@{
            'Nazwa'     = $_.displayName
            'Platforma' = $_.platform
            'Reguła'    = $_.rule
        }
    }
    New-M365TRCollectorResult -Component 'Intune' -Section 'Filtry przypisań (Assignment Filters)' `
        -Description 'Filtry przypisań (Assignment Filters) używane do zawezania zakresu przypisań zasad.' -Status 'ok' -Data $flat
}
