function New-M365TRDetailTable {
    <#
    .SYNOPSIS
    One sub-table ("Podstawowe"/"Ustawienia"/"Przypisania") inside a detailed per-object record.
    Rows with zero entries are dropped by the renderer, so it's safe to always include a table
    even when e.g. an object has no assignments.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Title, [object[]]$Rows = @())
    [PSCustomObject]@{ Title = $Title; Rows = @($Rows) }
}

function New-M365TRDetailRecord {
    <#
    .SYNOPSIS
    One object's full detail record (e.g. one Intune app, one compliance policy, one Conditional
    Access policy) for a "Records" collector result - renders as a named block containing all its
    detail tables, one after another.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Name, [object[]]$Tables = @())
    [PSCustomObject]@{ Name = $Name; Tables = @($Tables) }
}
