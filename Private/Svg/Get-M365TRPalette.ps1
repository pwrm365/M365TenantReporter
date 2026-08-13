function Get-M365TRPalette {
    <#
    .SYNOPSIS
    Validated categorical + status palette (light mode) used by every SVG chart, so
    color is applied consistently everywhere instead of re-picked per chart.
    #>
    [PSCustomObject]@{
        Categorical = @('#2a78d6', '#eb6834', '#1baf7a', '#eda100', '#e87ba4', '#008300', '#4a3aa7', '#e34948')
        Status      = @{
            ok                 = '#0ca30c'
            empty              = '#898781'
            'skipped-permission' = '#fab219'
            'skipped-license'  = '#fab219'
            error              = '#d03b3b'
        }
        Ink = @{
            Primary   = '#0b0b0b'
            Secondary = '#52514e'
            Muted     = '#898781'
            Grid      = '#e1e0d9'
            Baseline  = '#c3c2b7'
        }
        Surface = '#fcfcfb'
    }
}
