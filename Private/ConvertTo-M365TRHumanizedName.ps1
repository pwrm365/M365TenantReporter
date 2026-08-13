function ConvertTo-M365TRHumanizedName {
    <#
    .SYNOPSIS
    Fallback label for any property name without a curated Polish translation: splits
    camelCase into separate, title-cased words so nothing is shown as a raw API property name.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Name)
    # Rozdziela na słowa przy przejsciu mala->duza litera oraz na granicy akronimu (np. "URL" w
    # "SiteURLPath"), ale nie rozbija samego akronimu litera po literze ("UI" zostaje "UI", nie "U I").
    $spaced = [regex]::Replace($Name, '(?<=[a-z0-9])(?=[A-Z])', ' ')
    $spaced = [regex]::Replace($spaced, '(?<=[A-Z])(?=[A-Z][a-z])', ' ')
    return (Get-Culture).TextInfo.ToTitleCase($spaced.ToLower())
}
