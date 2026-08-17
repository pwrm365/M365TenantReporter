function Resolve-M365TRGroupName {
    <#
    .SYNOPSIS
    Resolves an Entra ID group ID to its display name, cached per process. Shared by assignment
    resolution (Get-M365TRAssignmentRows) and Conditional Access policy formatting, since both
    need the same lookup and the same "All Users"-style groups tend to recur across both.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Context, [string]$GroupId)

    if (-not $GroupId) { return $GroupId }
    if (-not $script:M365TRGroupNameCache) { $script:M365TRGroupNameCache = @{} }
    if ($script:M365TRGroupNameCache.ContainsKey($GroupId)) { return $script:M365TRGroupNameCache[$GroupId] }
    $name = $GroupId
    try {
        $r = Invoke-M365TRGraphRequest -Context $Context -Path "/groups/$GroupId`?`$select=displayName"
        if ($r.Success -and $r.Data.Count -gt 0 -and $r.Data[0].displayName) { $name = $r.Data[0].displayName }
    } catch {}
    $script:M365TRGroupNameCache[$GroupId] = $name
    return $name
}

function Get-M365TRAssignmentRows {
    <#
    .SYNOPSIS
    Turns a Graph `.../assignments` array (device compliance/configuration policies, Settings
    Catalog policies, mobile apps, ...) into readable "Przypisania" table rows: resolves
    groupId/assignmentFilterId to display names via Microsoft Graph, one row per assignment
    target. Group and filter names are cached for the lifetime of the PowerShell process
    (module-scoped), since the same groups (e.g. "All Users") get assigned to dozens of policies
    in a typical tenant and re-resolving them every time would multiply the number of Graph calls
    for no benefit.
    .PARAMETER Assignments
    The raw `assignments` array as returned by Microsoft Graph (each item has a `target` object).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Context,
        [object[]]$Assignments = @()
    )

    if (-not $script:M365TRFilterNameCache) { $script:M365TRFilterNameCache = @{} }

    function Resolve-FilterName([string]$FilterId) {
        if (-not $FilterId -or $FilterId -eq '00000000-0000-0000-0000-000000000000') { return $null }
        if ($script:M365TRFilterNameCache.ContainsKey($FilterId)) { return $script:M365TRFilterNameCache[$FilterId] }
        $name = $FilterId
        try {
            $r = Invoke-M365TRGraphRequest -Context $Context -Path "/deviceManagement/assignmentFilters/$FilterId`?`$select=displayName"
            if ($r.Success -and $r.Data.Count -gt 0 -and $r.Data[0].displayName) { $name = $r.Data[0].displayName }
        } catch {}
        $script:M365TRFilterNameCache[$FilterId] = $name
        return $name
    }

    if (@($Assignments).Count -eq 0) { return @() }

    foreach ($a in $Assignments) {
        $target = $a.target
        $type = "$($target.'@odata.type')"

        $mode = if ($type -match 'exclusionGroupAssignmentTarget') { 'Wykluczone' } else { 'Zawarte' }
        $group = switch -Regex ($type) {
            'allDevicesAssignmentTarget'       { 'Wszystkie urządzenia' }
            'allLicensedUsersAssignmentTarget' { 'Wszyscy użytkownicy' }
            default                            { Resolve-M365TRGroupName -Context $Context -GroupId $target.groupId }
        }
        $filterName = Resolve-FilterName $target.deviceAndAppManagementAssignmentFilterId
        $filterMode = if ($filterName) { $target.deviceAndAppManagementAssignmentFilterType } else { $null }

        $row = [ordered]@{
            'Tryb grupy'  = $mode
            'Grupa'       = $group
        }
        if ($a.intent) { $row['Intencja'] = $a.intent }
        $row['Filtruj'] = if ($filterName) { $filterName } else { 'Brak' }
        $row['Tryb filtru'] = if ($filterMode) { $filterMode } else { 'Brak' }
        [PSCustomObject]$row
    }
}
