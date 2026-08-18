function New-SvgBarChart {
    <#
    .SYNOPSIS
    Horizontal bar chart. Categories are the identity being shown, so each bar takes the
    next fixed categorical slot; direct value label at the tip, category label on the axis -
    no legend needed (identity is already named on the axis). Caps at 8 bars and folds the
    remainder into an explicit "Inne" bucket rather than truncating silently.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object[]]$Items,
        [string]$Title = $null,
        [int]$Width = 640,
        [ValidateSet('pl', 'en')][string]$Language = 'pl'
    )
    $palette = Get-M365TRPalette
    $ink = $palette.Ink

    $data = @($Items | Sort-Object -Property Value -Descending)
    $maxItems = 8
    if ($data.Count -gt $maxItems) {
        $head = $data[0..($maxItems - 2)]
        $restItems = $data[($maxItems - 1)..($data.Count - 1)]
        $restSum = ($restItems | Measure-Object -Property Value -Sum).Sum
        $otherLabel = if ($Language -eq 'en') { 'Other' } else { 'Inne' }
        $data = @($head) + [PSCustomObject]@{ Label = "$otherLabel ($($restItems.Count))"; Value = $restSum }
    }
    if ($data.Count -eq 0) { return '' }

    $barHeight = 22
    $gap = 12
    $labelWidth = 200
    $chartWidth = $Width - $labelWidth - 60
    $maxValue = ($data | Measure-Object -Property Value -Maximum).Maximum
    if (-not $maxValue -or $maxValue -le 0) { $maxValue = 1 }

    $height = ($data.Count * ($barHeight + $gap)) + $gap
    $rows = New-Object System.Collections.Generic.List[string]
    $y = $gap
    $i = 0
    # Etykiety osi są prawostronnie wyrownane do x=labelWidth - bez limitu długości dlugie nazwy
    # (np. pełne typy profili Intune) wyplywalyby za lewa krawedz SVG i byly ucinane w polowie.
    $maxLabelChars = 26
    foreach ($item in $data) {
        $color = $palette.Categorical[$i % $palette.Categorical.Count]
        $barLen = [Math]::Max(2, [Math]::Round(($item.Value / $maxValue) * $chartWidth))
        $fullLabel = [string]$item.Label
        $shortLabel = if ($fullLabel.Length -gt $maxLabelChars) { $fullLabel.Substring(0, $maxLabelChars - 1) + '…' } else { $fullLabel }
        $labelEsc = ConvertTo-M365TRHtmlEncoded $shortLabel
        $titleEsc = ConvertTo-M365TRHtmlEncoded $fullLabel
        $textY = [Math]::Round($y + $barHeight * 0.7)
        $rows.Add("<text x='$($labelWidth - 10)' y='$textY' text-anchor='end' font-size='12' fill='$($ink.Secondary)'><title>$titleEsc</title>$labelEsc</text>")
        $rows.Add("<rect x='$labelWidth' y='$y' width='$barLen' height='$barHeight' rx='4' fill='$color' />")
        $rows.Add("<text x='$($labelWidth + $barLen + 8)' y='$textY' font-size='12' fill='$($ink.Primary)'>$($item.Value)</text>")
        $y += $barHeight + $gap
        $i++
    }

    $titleHtml = if ($Title) { "<div class='chart-title'>$(ConvertTo-M365TRHtmlEncoded $Title)</div>" } else { '' }

    @"
<div class="chart-block">
  $titleHtml
  <svg viewBox="0 0 $Width $height" width="100%" height="$height" role="img" aria-label="$(ConvertTo-M365TRHtmlEncoded $Title)">
    $($rows -join "`n")
  </svg>
</div>
"@
}
