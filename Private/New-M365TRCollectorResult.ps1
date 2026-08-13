function New-M365TRCollectorResult {
    <#
    .SYNOPSIS
    Builds the single standard shape every collector returns. Collectors never construct
    this object literally, so the shape can never drift between the ~28 collector files.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Component,
        [Parameter(Mandatory)][string]$Section,
        [string]$Description = "",
        [ValidateSet('ok', 'empty', 'skipped-permission', 'skipped-license', 'error')]
        [string]$Status = 'ok',
        [string]$Message = $null,
        [object[]]$Data = @(),
        [switch]$Transpose
    )

    [PSCustomObject]@{
        Component   = $Component
        Section     = $Section
        Description = $Description
        Status      = $Status
        Message     = $Message
        Data        = @($Data)
        Transpose   = [bool]$Transpose
    }
}
