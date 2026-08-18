function New-SvgDonutChart {
    <#
    .SYNOPSIS
    Donut chart for a small proportion breakdown (2-6 slices), e.g. the collection health
    summary (ok / skipped-permission / skipped-license / error). Always ships a legend
    since it's multi-series - identity is never color-alone.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object[]]$Items,
        [string]$Title = $null,
        [int]$Size = 200,
        [switch]$UseStatusPalette
    )
    $palette = Get-M365TRPalette
    $total = ($Items | Measure-Object -Property Value -Sum).Sum
    if (-not $total -or $total -le 0) { $total = 1 }

    $cx = [Math]::Round($Size / 2, 2)
    $cy = $cx
    $r = [Math]::Round(($Size / 2) - 10, 2)
    $strokeWidth = 28
    $circumference = [Math]::Round(2 * [Math]::PI * $r, 4)

    $segments = New-Object System.Collections.Generic.List[string]
    $legend = New-Object System.Collections.Generic.List[string]
    $offset = 0.0
    $i = 0
    foreach ($item in $Items) {
        $color = if ($item.Color) {
            $item.Color
        } elseif ($UseStatusPalette -and $palette.Status.ContainsKey($item.Label)) {
            $palette.Status[$item.Label]
        } else {
            $palette.Categorical[$i % $palette.Categorical.Count]
        }
        $fraction = $item.Value / $total
        $dash = [Math]::Round($fraction * $circumference, 4)
        $dashAdj = [Math]::Max(0, $dash - 2)
        $remainder = [Math]::Round($circumference - $dashAdj, 4)
        $segments.Add("<circle cx='$cx' cy='$cy' r='$r' fill='none' stroke='$color' stroke-width='$strokeWidth' stroke-dasharray='$dashAdj $remainder' stroke-dashoffset='-$offset' transform='rotate(-90 $cx $cy)' />")
        $offset += $dash
        $pct = [Math]::Round($fraction * 100)
        $displayLabel = if ($item.DisplayLabel) { $item.DisplayLabel } else { $item.Label }
        $legendLabel = ConvertTo-M365TRHtmlEncoded ([string]$displayLabel)
        $legend.Add("<div class='legend-item'><span class='legend-swatch' style='background:$color'></span>$legendLabel &mdash; $($item.Value) ($pct%)</div>")
        $i++
    }

    $titleHtml = if ($Title) { "<div class='chart-title'>$(ConvertTo-M365TRHtmlEncoded $Title)</div>" } else { '' }

    @"
<div class="chart-block donut-block">
  $titleHtml
  <div class="donut-row">
    <svg viewBox="0 0 $Size $Size" width="$Size" height="$Size" role="img" aria-label="$(ConvertTo-M365TRHtmlEncoded $Title)">
      $($segments -join "`n")
    </svg>
    <div class="legend">$($legend -join "`n")</div>
  </div>
</div>
"@
}
