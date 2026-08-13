function New-SvgStatTile {
    <#
    .SYNOPSIS
    A KPI stat tile: big value + label + a status accent bar. No plot, so no legend/hover needed.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Label,
        [Parameter(Mandatory)][string]$Value,
        [ValidateSet('ok', 'warning', 'critical', 'neutral')]
        [string]$Status = 'neutral'
    )
    $palette = Get-M365TRPalette
    $accent = switch ($Status) {
        'ok'       { $palette.Status.ok }
        'warning'  { $palette.Status.'skipped-permission' }
        'critical' { $palette.Status.error }
        default    { $palette.Categorical[0] }
    }
    $labelEsc = ConvertTo-M365TRHtmlEncoded $Label
    $valueEsc = ConvertTo-M365TRHtmlEncoded $Value

    @"
<div class="stat-tile">
  <div class="stat-tile-accent" style="background:$accent"></div>
  <div class="stat-tile-value">$valueEsc</div>
  <div class="stat-tile-label">$labelEsc</div>
</div>
"@
}
