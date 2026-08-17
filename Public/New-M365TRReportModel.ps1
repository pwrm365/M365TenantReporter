function New-M365TRReportModel {
    <#
    .SYNOPSIS
    Normalizes raw collector results (from Invoke-M365TRCollection) into the structure the
    HTML/PDF renderer consumes: chapters per component, an overall health summary, and an
    appendix of everything that was skipped and why.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object[]]$Results,
        [Parameter(Mandatory)][string]$TenantName,
        [string]$LogoDataUri = $null,
        [ValidateSet('pl', 'en')][string]$Language = 'pl'
    )

    $componentOrder = @('EntraID', 'Intune', 'Windows365', 'CloudPrint', 'InformationProtection', 'Exchange', 'Teams', 'SharePoint', 'Purview')
    $componentTitles = @{
        EntraID               = 'Entra ID (Azure AD)'
        Intune                = 'Intune / Endpoint Manager'
        Windows365            = 'Windows 365'
        CloudPrint            = 'Universal Print'
        InformationProtection = 'Information Protection'
        Exchange              = 'Exchange Online'
        Teams                 = 'Microsoft Teams'
        SharePoint            = 'SharePoint / OneDrive'
        Purview               = 'Purview (Security & Compliance)'
    }

    # Jeśli caly dzial (komponent) jest niedostępny w tym tenancie - wszystkie jego sekcje są
    # pominięte z powodu uprawnień/licencji, bez ani jednej realnie zebranej danej (ok/empty) -
    # nie pokazujemy całego rozdzialu w treści raportu (byla to strona pełna ostrzezen o niczym
    # nieuzywanym module, np. Windows 365 gdy tenant go nie ma). Załącznik na koncu i tak
    # dokumentuje ten fakt, więc informacja nie ginie, tylko znika balast z glownej treści.
    $groupDefs = Get-M365TRSectionGroups
    $chapters = foreach ($comp in $componentOrder) {
        $sections = @($Results | Where-Object { $_.Component -eq $comp })
        if ($sections.Count -eq 0) { continue }
        $hasUsableData = @($sections | Where-Object { $_.Status -in @('ok', 'empty') }).Count -gt 0
        if (-not $hasUsableData) { continue }

        $matchedNames = @{}
        $groups = @()
        if ($groupDefs.Contains($comp)) {
            $groups = foreach ($groupDef in $groupDefs[$comp]) {
                $matched = foreach ($sectionName in $groupDef.Sections) {
                    $found = $sections | Where-Object { $_.Section -eq $sectionName -and -not $matchedNames.ContainsKey($_.Section) } | Select-Object -First 1
                    if ($found) { $matchedNames[$found.Section] = $true; $found }
                }
                $matched = @($matched)
                if ($matched.Count -gt 0) { [PSCustomObject]@{ Name = $groupDef.Name; Sections = $matched } }
            }
            $groups = @($groups)
        }
        $leftover = @($sections | Where-Object { -not $matchedNames.ContainsKey($_.Section) })
        if ($leftover.Count -gt 0) {
            $leftoverName = if ($groups.Count -gt 0) { ConvertTo-M365TRLocalizedText -Text 'Pozostałe ustawienia' -Language $Language } else { $null }
            $groups = @($groups) + [PSCustomObject]@{ Name = $leftoverName; Sections = @($leftover | Sort-Object Section) }
        }

        [PSCustomObject]@{
            Component = $comp
            Title     = $componentTitles[$comp]
            Sections  = $sections | Sort-Object Section
            Groups    = @($groups)
        }
    }

    $health = [ordered]@{
        ok                   = @($Results | Where-Object Status -eq 'ok').Count
        empty                = @($Results | Where-Object Status -eq 'empty').Count
        'skipped-permission' = @($Results | Where-Object Status -eq 'skipped-permission').Count
        'skipped-license'    = @($Results | Where-Object Status -eq 'skipped-license').Count
        error                = @($Results | Where-Object Status -eq 'error').Count
    }

    $appendix = @($Results | Where-Object { $_.Status -in @('skipped-permission', 'skipped-license', 'error') } | Sort-Object Component, Section)

    [PSCustomObject]@{
        TenantName    = $TenantName
        LogoDataUri   = $LogoDataUri
        GeneratedAt   = Get-Date
        TotalSections = $Results.Count
        Chapters      = @($chapters)
        Health        = $health
        Appendix      = $appendix
        Language      = $Language
    }
}
