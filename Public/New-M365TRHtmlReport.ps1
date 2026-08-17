function New-M365TRHtmlReport {
    <#
    .SYNOPSIS
    Renders a report model (from New-M365TRReportModel) into a single self-contained HTML
    file: cover, KPI dashboard, table of contents, one chapter per component (tables + charts),
    and an appendix of everything that was skipped and why. Shell (cover/footer/head) comes from
    an external template file (Report\Templates\report-template.html) with {{TOKEN}} placeholders,
    so the visual design can be tweaked without touching this generator.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Model,
        [Parameter(Mandatory)][string]$OutputPath
    )

    $lang = Get-M365TRLanguage -Context $Model
    $ui = Get-M365TRUiStrings -Language $lang
    function Get-Loc([string]$Text) { ConvertTo-M365TRLocalizedText -Text $Text -Language $lang }
    function Get-LocValue($Value) {
        if ($Value -is [bool]) { return $(if ($Value) { Get-Loc 'Tak' } else { Get-Loc 'Nie' }) }
        return (Get-Loc "$Value")
    }

    function ConvertTo-SafeId([string]$Text) {
        ($Text -replace '[^a-zA-Z0-9]', '')
    }

    function Get-SectionByMatch($Component, $Pattern) {
        $Model.Chapters | Where-Object Component -eq $Component |
            Select-Object -ExpandProperty Sections |
            Where-Object { $_.Section -match $Pattern -and $_.Status -eq 'ok' } |
            Select-Object -First 1
    }

    function Get-BreakdownChartHtml($Section) {
        if ($Section.Transpose -or $Section.Records -or $Section.Data.Count -lt 2) { return $null }
        $candidateColumns = @('Typ', 'Platforma', 'Stan', 'Status', 'Domyślna', 'Zweryfikowana', 'Wbudowana')
        $props = $Section.Data[0].PSObject.Properties.Name
        $col = $candidateColumns | Where-Object { $_ -in $props } | Select-Object -First 1
        if (-not $col) { return $null }
        $groups = $Section.Data | Group-Object -Property $col | Where-Object { $_.Name } | Sort-Object Count -Descending
        if ($groups.Count -lt 2 -or $groups.Count -gt 12) { return $null }
        $items = $groups | ForEach-Object { [PSCustomObject]@{ Label = $_.Name; Value = $_.Count } }
        New-SvgBarChart -Items $items -Title "$($ui.BreakdownPrefix): $(Get-Loc $col)"
    }

    $statusLabel = @{
        ok                   = $ui.StatusOk
        empty                = $ui.StatusEmpty
        'skipped-permission' = $ui.StatusSkippedPerm
        'skipped-license'    = $ui.StatusSkippedLic
        error                = $ui.StatusError
    }
    $statusClass = @{
        ok                   = 'badge-ok'
        empty                = 'badge-neutral'
        'skipped-permission' = 'badge-warning'
        'skipped-license'    = 'badge-warning'
        error                = 'badge-critical'
    }

    # ---------- KPI dashboard ----------
    $okAndEmpty = $Model.Health.ok + $Model.Health.empty
    $skipped = $Model.Health.'skipped-permission' + $Model.Health.'skipped-license'
    $tiles = New-Object System.Collections.Generic.List[string]
    $tiles.Add((New-SvgStatTile -Label $ui.TileCollected -Value "$okAndEmpty / $($Model.TotalSections)" -Status 'ok'))
    $tiles.Add((New-SvgStatTile -Label $ui.TileSkipped -Value "$skipped" -Status 'warning'))
    $tiles.Add((New-SvgStatTile -Label $ui.TileErrors -Value "$($Model.Health.error)" -Status $(if ($Model.Health.error -gt 0) { 'critical' } else { 'ok' })))

    $headline = @(
        @{ Component = 'EntraID'; Pattern = 'Conditional Access'; Label = $ui.HeadlineCa }
        @{ Component = 'Intune'; Pattern = 'zgodności'; Label = $ui.HeadlineCompliance }
        @{ Component = 'Intune'; Pattern = 'Aplikacje mobilne'; Label = $ui.HeadlineApps }
        @{ Component = 'EntraID'; Pattern = 'Domeny'; Label = $ui.HeadlineDomains }
    )
    foreach ($h in $headline) {
        $s = Get-SectionByMatch -Component $h.Component -Pattern $h.Pattern
        if ($s) { $tiles.Add((New-SvgStatTile -Label $h.Label -Value "$($s.Data.Count)" -Status 'neutral')) }
    }

    $healthItems = $Model.Health.GetEnumerator() | Where-Object { $_.Value -gt 0 } |
        ForEach-Object { [PSCustomObject]@{ Label = $_.Key; Value = $_.Value } }
    $healthDonut = if ($healthItems.Count -gt 1) { New-SvgDonutChart -Items $healthItems -Title $ui.DonutTitle -UseStatusPalette } else { '' }
    $dashboardHtml = "<div class='tiles'>$($tiles -join "`n")</div>`n$healthDonut"

    # ---------- Table of contents ----------
    $tocItems = $Model.Chapters | ForEach-Object {
        "<li><a href='#$(ConvertTo-SafeId $_.Component)'>$(ConvertTo-M365TRHtmlEncoded $_.Title)</a></li>"
    }
    $tocHtml = "<ol class='toc'>$($tocItems -join "`n")<li><a href='#appendix'>$(ConvertTo-M365TRHtmlEncoded $ui.TocAppendixLink)</a></li></ol>"

    # ---------- Chapters ----------
    function Get-GenericTableHtml($Rows, [switch]$AsKv) {
        if (-not $Rows -or @($Rows).Count -eq 0) { return '' }
        $cols = $Rows[0].PSObject.Properties.Name
        $tableClass = if ($AsKv) { 'data-table kv-detail-table' } else { 'data-table' }
        $headerRow = "<tr>$(($cols | ForEach-Object { "<th>$(ConvertTo-M365TRHtmlEncoded (Get-Loc $_))</th>" }) -join '')</tr>"
        $bodyRows = $Rows | ForEach-Object {
            $row = $_
            "<tr>$(($cols | ForEach-Object { "<td>$(ConvertTo-M365TRHtmlEncoded (Get-LocValue $row.$_))</td>" }) -join '')</tr>"
        }
        "<div class='table-wrap'><table class='$tableClass'><thead>$headerRow</thead><tbody>$($bodyRows -join "`n")</tbody></table></div>"
    }

    function Get-DetailRecordsHtml($Records) {
        $blocks = foreach ($rec in $Records) {
            $tableBlocks = foreach ($t in $rec.Tables) {
                if (-not $t.Rows -or @($t.Rows).Count -eq 0) { continue }
                $tableHtml = Get-GenericTableHtml -Rows $t.Rows -AsKv
                "<p class='subtable-title'>$(ConvertTo-M365TRHtmlEncoded (Get-Loc $t.Title))</p>$tableHtml"
            }
            "<div class='detail-record'><h4 class='detail-record-title'>$(ConvertTo-M365TRHtmlEncoded $rec.Name)</h4>$($tableBlocks -join "`n")</div>"
        }
        $blocks -join "`n"
    }

    function Get-SectionBlockHtml($Component, $Section) {
        $sid = "$(ConvertTo-SafeId $Component)_$(ConvertTo-SafeId $Section.Section)"
        $badge = "<span class='badge $($statusClass[$Section.Status])'>$($statusLabel[$Section.Status])</span>"
        $desc = if ($Section.Description) { "<p class='section-desc'>$(ConvertTo-M365TRHtmlEncoded (Get-Loc $Section.Description))</p>" } else { '' }

        $body = ''
        if ($Section.Status -in @('skipped-permission', 'skipped-license', 'error')) {
            $body = "<div class='note note-$($statusClass[$Section.Status])'>$(ConvertTo-M365TRHtmlEncoded $Section.Message)</div>"
        } elseif ($Section.Status -eq 'empty' -or $Section.Data.Count -eq 0) {
            $body = "<div class='note note-neutral'>$(ConvertTo-M365TRHtmlEncoded $ui.NoDataInTenant)</div>"
        } elseif ($Section.Transpose) {
            $obj = $Section.Data[0]
            $rows = $obj.PSObject.Properties | ForEach-Object {
                "<tr><th>$(ConvertTo-M365TRHtmlEncoded (Get-Loc $_.Name))</th><td>$(ConvertTo-M365TRHtmlEncoded (Get-LocValue $_.Value))</td></tr>"
            }
            $body = "<table class='kv-table'>$($rows -join "`n")</table>"
        } elseif ($Section.Records) {
            $body = Get-DetailRecordsHtml -Records $Section.Data
        } else {
            $chart = Get-BreakdownChartHtml -Section $Section
            $chartHtml = if ($chart) { $chart } else { '' }
            $tableHtml = Get-GenericTableHtml -Rows $Section.Data
            $body = "$chartHtml$tableHtml"
        }

        @"
<section class="doc-section" id="$sid">
  <h3>$(ConvertTo-M365TRHtmlEncoded (Get-Loc $Section.Section)) $badge</h3>
  $desc
  $body
</section>
"@
    }

    $chapterBlocks = foreach ($chapter in $Model.Chapters) {
        $showGroupHeaders = $chapter.Groups.Count -gt 1
        $groupBlocks = foreach ($group in $chapter.Groups) {
            $sectionBlocks = foreach ($section in $group.Sections) { Get-SectionBlockHtml -Component $chapter.Component -Section $section }
            $groupHeaderHtml = if ($showGroupHeaders -and $group.Name) { "<h4 class='section-group-title'>$(ConvertTo-M365TRHtmlEncoded $group.Name)</h4>" } else { '' }
            "<div class='section-group'>$groupHeaderHtml$($sectionBlocks -join "`n")</div>"
        }

        # Mini-spis treści rozdziału - przydatny, gdy rozdział ma kilkanaście sekcji w kilku
        # grupach tematycznych zamiast jednej płaskiej listy.
        $miniToc = ''
        if ($showGroupHeaders) {
            $miniTocGroups = foreach ($group in $chapter.Groups) {
                $links = foreach ($section in $group.Sections) {
                    $sid = "$(ConvertTo-SafeId $chapter.Component)_$(ConvertTo-SafeId $section.Section)"
                    "<li><a href='#$sid'>$(ConvertTo-M365TRHtmlEncoded (Get-Loc $section.Section))</a></li>"
                }
                $groupLabel = if ($group.Name) { "<span class='chapter-toc-group'>$(ConvertTo-M365TRHtmlEncoded $group.Name)</span>" } else { '' }
                "<li>$groupLabel<ul>$($links -join "`n")</ul></li>"
            }
            $miniToc = "<nav class='chapter-toc'><ul>$($miniTocGroups -join "`n")</ul></nav>"
        }

        @"
<section class="chapter" id="$(ConvertTo-SafeId $chapter.Component)">
  <h2>$(ConvertTo-M365TRHtmlEncoded $chapter.Title)</h2>
  $miniToc
  $($groupBlocks -join "`n")
</section>
"@
    }

    # ---------- Appendix ----------
    $appendixRows = $Model.Appendix | ForEach-Object {
        "<tr><td>$(ConvertTo-M365TRHtmlEncoded $_.Component)</td><td>$(ConvertTo-M365TRHtmlEncoded (Get-Loc $_.Section))</td><td><span class='badge $($statusClass[$_.Status])'>$($statusLabel[$_.Status])</span></td><td>$(ConvertTo-M365TRHtmlEncoded $_.Message)</td></tr>"
    }
    $appendixHtml = if ($Model.Appendix.Count -gt 0) {
        "<table class='data-table'><thead><tr><th>$($ui.AppendixColComponent)</th><th>$($ui.AppendixColSection)</th><th>$($ui.AppendixColStatus)</th><th>$($ui.AppendixColReason)</th></tr></thead><tbody>$($appendixRows -join "`n")</tbody></table>"
    } else {
        "<div class='note note-ok'>$(ConvertTo-M365TRHtmlEncoded $ui.AppendixAllOk)</div>"
    }
    $appendixChapterHtml = @"
<section class="chapter" id="appendix">
  <h2 data-kicker="$(ConvertTo-M365TRHtmlEncoded $ui.AppendixKicker)">$(ConvertTo-M365TRHtmlEncoded $ui.AppendixTitle)</h2>
  <p class="section-desc">$(ConvertTo-M365TRHtmlEncoded $ui.AppendixDesc)</p>
  $appendixHtml
</section>
"@
    $chaptersHtml = ($chapterBlocks -join "`n") + "`n" + $appendixChapterHtml

    # ---------- Okładka: fakty i marka ----------
    $tenantEsc = ConvertTo-M365TRHtmlEncoded $Model.TenantName
    $generatedAt = $Model.GeneratedAt.ToString('dd.MM.yyyy HH:mm')
    $orgSection = Get-SectionByMatch -Component 'EntraID' -Pattern 'Organizacja'
    $orgData = if ($orgSection -and $orgSection.Data.Count -gt 0) { $orgSection.Data[0] } else { $null }
    $domainsSection = Get-SectionByMatch -Component 'EntraID' -Pattern 'Domeny'

    function New-M365TRCoverFact([string]$Label, [string]$Value, [switch]$Mono) {
        if (-not $Value) { $Value = $ui.NoDataFallback }
        $cls = if ($Mono) { " class='mono'" } else { '' }
        "<div><dt>$(ConvertTo-M365TRHtmlEncoded $Label)</dt><dd$cls>$(ConvertTo-M365TRHtmlEncoded $Value)</dd></div>"
    }
    $coverFactsHtml = @(
        New-M365TRCoverFact -Label $ui.FactTenantId -Value ([string]$orgData.'Identyfikator tenanta') -Mono
        New-M365TRCoverFact -Label $ui.FactPrimaryDomain -Value ([string]$orgData.'Domena podstawowa') -Mono
        New-M365TRCoverFact -Label $ui.FactCountry -Value ([string]$orgData.'Kraj')
        New-M365TRCoverFact -Label $ui.FactDomainCount -Value $(if ($domainsSection) { "$($domainsSection.Data.Count)" } else { $null })
        New-M365TRCoverFact -Label $ui.FactCollected -Value "$okAndEmpty / $($Model.TotalSections)"
        New-M365TRCoverFact -Label $ui.FactGeneratedAt -Value $generatedAt
    ) -join "`n"

    $coverMarkHtml = if ($Model.LogoDataUri) {
        "<img class='cover-logo' src='$($Model.LogoDataUri)' alt='Logo organizacji'>"
    } else {
        "<span>$tenantEsc</span>"
    }

    $css = Get-Content -Path (Join-Path $PSScriptRoot '..\Report\Templates\report.css.txt') -Raw -Encoding UTF8
    $template = Get-Content -Path (Join-Path $PSScriptRoot '..\Report\Templates\report-template.html') -Raw -Encoding UTF8

    $tokens = [ordered]@{
        HTML_LANG      = $ui.HtmlLang
        DOC_TITLE      = "$($ui.DocTitlePrefix) - $tenantEsc"
        STYLES         = $css
        COVER_MARK     = $coverMarkHtml
        TECH_DOC_LABEL = $ui.TechDocLabel
        COVER_EYEBROW  = $ui.DocTitlePrefix
        TENANT_NAME    = $tenantEsc
        COVER_SUBTITLE = $ui.CoverSubtitle
        COVER_FACTS    = $coverFactsHtml
        COVER_NOTE     = $ui.CoverNote
        SUMMARY_TITLE  = $ui.SummaryTitle
        DASHBOARD      = $dashboardHtml
        TOC_TITLE      = $ui.TocTitle
        TOC            = $tocHtml
        CHAPTERS       = $chaptersHtml
        FOOTER_LEFT    = "$($ui.FooterLeftPrefix) - $tenantEsc"
        FOOTER_RIGHT   = "$($ui.FooterRightPrefix) - $generatedAt"
    }

    # Replace zamiast -replace: treść sekcji zawiera $ i \, które w regexie by się rozjechały.
    $html = $template
    foreach ($key in $tokens.Keys) {
        $html = $html.Replace("{{$key}}", [string]$tokens[$key])
    }

    $dir = Split-Path -Parent $OutputPath
    if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($OutputPath, $html, $utf8NoBom)
    Write-Host "Raport HTML zapisany: $OutputPath"
    return $OutputPath
}
