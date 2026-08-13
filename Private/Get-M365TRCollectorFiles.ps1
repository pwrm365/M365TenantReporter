function Get-M365TRCollectorFiles {
    <#
    .SYNOPSIS
    Auto-discovers collector files. Filename convention: "<Component>.<Section>.ps1" maps to
    function "Get-Collector_<Component>_<Section>". Adding a new section is just dropping a new
    file here - nothing else to register.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ModuleRoot
    )
    $collectorPath = Join-Path $ModuleRoot 'Collectors'
    Get-ChildItem -Path $collectorPath -Filter '*.ps1' -File | Sort-Object Name | ForEach-Object {
        $parts = $_.BaseName -split '\.'
        $component = $parts[0]
        $section = if ($parts.Count -gt 1) { $parts[1] } else { $_.BaseName }
        [PSCustomObject]@{
            Path         = $_.FullName
            Component    = $component
            Section      = $section
            FunctionName = "Get-Collector_${component}_${section}"
        }
    }
}
