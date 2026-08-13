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
        if ($Section.Transpose -or $Section.Data.Count -lt 2) { return $null }
        $candidateColumns = @('Typ', 'Platforma', 'Stan', 'Status', 'Domyślna', 'Zweryfikowana', 'Wbudowana')
        $props = $Section.Data[0].PSObject.Properties.Name
        $col = $candidateColumns | Where-Object { $_ -in $props } | Select-Object -First 1
        if (-not $col) { return $null }
        $groups = $Section.Data | Group-Object -Property $col | Where-Object { $_.Name } | Sort-Object Count -Descending
        if ($groups.Count -lt 2 -or $groups.Count -gt 12) { return $null }
        $items = $groups | ForEach-Object { [PSCustomObject]@{ Label = $_.Name; Value = $_.Count } }
        New-SvgBarChart -Items $items -Title "Rozklad wg: $col"
    }

    $statusLabel = @{
        ok                   = 'OK'
        empty                = 'Brak danych'
        'skipped-permission' = 'Pominięto - brak uprawnień'
        'skipped-license'    = 'Pominięto - brak licencji'
        error                = 'Błąd'
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
    $tiles.Add((New-SvgStatTile -Label 'Zebrane sekcje' -Value "$okAndEmpty / $($Model.TotalSections)" -Status 'ok'))
    $tiles.Add((New-SvgStatTile -Label 'Pominięte (uprawnienia/licencja)' -Value "$skipped" -Status 'warning'))
    $tiles.Add((New-SvgStatTile -Label 'Błędy' -Value "$($Model.Health.error)" -Status $(if ($Model.Health.error -gt 0) { 'critical' } else { 'ok' })))

    $headline = @(
        @{ Component = 'EntraID'; Pattern = 'Conditional Access'; Label = 'Polityki Conditional Access' }
        @{ Component = 'Intune'; Pattern = 'zgodności'; Label = 'Polityki zgodności Intune' }
        @{ Component = 'Intune'; Pattern = 'Aplikacje mobilne'; Label = 'Aplikacje mobilne' }
        @{ Component = 'EntraID'; Pattern = 'Domeny'; Label = 'Domeny' }
    )
    foreach ($h in $headline) {
        $s = Get-SectionByMatch -Component $h.Component -Pattern $h.Pattern
        if ($s) { $tiles.Add((New-SvgStatTile -Label $h.Label -Value "$($s.Data.Count)" -Status 'neutral')) }
    }

    $healthItems = $Model.Health.GetEnumerator() | Where-Object { $_.Value -gt 0 } |
        ForEach-Object { [PSCustomObject]@{ Label = $_.Key; Value = $_.Value } }
    $healthDonut = if ($healthItems.Count -gt 1) { New-SvgDonutChart -Items $healthItems -Title 'Status zbierania danych' -UseStatusPalette } else { '' }
    $dashboardHtml = "<div class='tiles'>$($tiles -join "`n")</div>`n$healthDonut"

    # ---------- Table of contents ----------
    $tocItems = $Model.Chapters | ForEach-Object {
        "<li><a href='#$(ConvertTo-SafeId $_.Component)'>$(ConvertTo-M365TRHtmlEncoded $_.Title)</a></li>"
    }
    $tocHtml = "<ol class='toc'>$($tocItems -join "`n")<li><a href='#appendix'>Załącznik: niezebrane dane</a></li></ol>"

    # ---------- Chapters ----------
    function Get-SectionBlockHtml($Component, $Section) {
        $sid = "$(ConvertTo-SafeId $Component)_$(ConvertTo-SafeId $Section.Section)"
        $badge = "<span class='badge $($statusClass[$Section.Status])'>$($statusLabel[$Section.Status])</span>"
        $desc = if ($Section.Description) { "<p class='section-desc'>$(ConvertTo-M365TRHtmlEncoded $Section.Description)</p>" } else { '' }

        $body = ''
        if ($Section.Status -in @('skipped-permission', 'skipped-license', 'error')) {
            $body = "<div class='note note-$($statusClass[$Section.Status])'>$(ConvertTo-M365TRHtmlEncoded $Section.Message)</div>"
        } elseif ($Section.Status -eq 'empty' -or $Section.Data.Count -eq 0) {
            $body = "<div class='note note-neutral'>Brak danych w tym tenancie.</div>"
        } elseif ($Section.Transpose) {
            $obj = $Section.Data[0]
            $rows = $obj.PSObject.Properties | ForEach-Object {
                $val = if ($_.Value -is [bool]) { if ($_.Value) { 'Tak' } else { 'Nie' } } else { [string]$_.Value }
                "<tr><th>$(ConvertTo-M365TRHtmlEncoded $_.Name)</th><td>$(ConvertTo-M365TRHtmlEncoded $val)</td></tr>"
            }
            $body = "<table class='kv-table'>$($rows -join "`n")</table>"
        } else {
            $chart = Get-BreakdownChartHtml -Section $Section
            $chartHtml = if ($chart) { $chart } else { '' }
            $cols = $Section.Data[0].PSObject.Properties.Name
            $headerRow = "<tr>$(($cols | ForEach-Object { "<th>$(ConvertTo-M365TRHtmlEncoded $_)</th>" }) -join '')</tr>"
            $bodyRows = $Section.Data | ForEach-Object {
                $row = $_
                "<tr>$(($cols | ForEach-Object { $v = $row.$_; $s = if ($v -is [bool]) { if ($v) { 'Tak' } else { 'Nie' } } else { [string]$v }; "<td>$(ConvertTo-M365TRHtmlEncoded $s)</td>" }) -join '')</tr>"
            }
            $body = "$chartHtml<div class='table-wrap'><table class='data-table'><thead>$headerRow</thead><tbody>$($bodyRows -join "`n")</tbody></table></div>"
        }

        @"
<section class="doc-section" id="$sid">
  <h3>$(ConvertTo-M365TRHtmlEncoded $Section.Section) $badge</h3>
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
                    "<li><a href='#$sid'>$(ConvertTo-M365TRHtmlEncoded $section.Section)</a></li>"
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
        "<tr><td>$(ConvertTo-M365TRHtmlEncoded $_.Component)</td><td>$(ConvertTo-M365TRHtmlEncoded $_.Section)</td><td><span class='badge $($statusClass[$_.Status])'>$($statusLabel[$_.Status])</span></td><td>$(ConvertTo-M365TRHtmlEncoded $_.Message)</td></tr>"
    }
    $appendixHtml = if ($Model.Appendix.Count -gt 0) {
        "<table class='data-table'><thead><tr><th>Komponent</th><th>Sekcja</th><th>Status</th><th>Powód</th></tr></thead><tbody>$($appendixRows -join "`n")</tbody></table>"
    } else {
        "<div class='note note-ok'>Wszystkie sekcje zostały zebrane pomyślnie.</div>"
    }
    $appendixChapterHtml = @"
<section class="chapter" id="appendix">
  <h2>Załącznik: niezebrane dane</h2>
  <p class="section-desc">Sekcje pominięte z powodu brakujących uprawnień/licencji lub błędu połączenia z Microsoft Graph.</p>
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
        if (-not $Value) { $Value = 'brak danych' }
        $cls = if ($Mono) { " class='mono'" } else { '' }
        "<div><dt>$(ConvertTo-M365TRHtmlEncoded $Label)</dt><dd$cls>$(ConvertTo-M365TRHtmlEncoded $Value)</dd></div>"
    }
    $coverFactsHtml = @(
        New-M365TRCoverFact -Label 'Identyfikator tenanta' -Value ([string]$orgData.'Identyfikator tenanta') -Mono
        New-M365TRCoverFact -Label 'Domena podstawowa' -Value ([string]$orgData.'Domena podstawowa') -Mono
        New-M365TRCoverFact -Label 'Kraj' -Value ([string]$orgData.'Kraj')
        New-M365TRCoverFact -Label 'Liczba domen' -Value $(if ($domainsSection) { "$($domainsSection.Data.Count)" } else { $null })
        New-M365TRCoverFact -Label 'Zebrane sekcje' -Value "$okAndEmpty / $($Model.TotalSections)"
        New-M365TRCoverFact -Label 'Data wygenerowania' -Value $generatedAt
    ) -join "`n"

    $coverMarkHtml = if ($Model.LogoDataUri) {
        "<img class='cover-logo' src='$($Model.LogoDataUri)' alt='Logo organizacji'>"
    } else {
        "<span>$tenantEsc</span>"
    }

    $css = Get-Content -Path (Join-Path $PSScriptRoot '..\Report\Templates\report.css.txt') -Raw -Encoding UTF8
    $template = Get-Content -Path (Join-Path $PSScriptRoot '..\Report\Templates\report-template.html') -Raw -Encoding UTF8

    $tokens = [ordered]@{
        DOC_TITLE      = "Dokumentacja środowiska Microsoft 365 - $tenantEsc"
        STYLES         = $css
        COVER_MARK     = $coverMarkHtml
        COVER_EYEBROW  = 'Dokumentacja środowiska Microsoft 365'
        TENANT_NAME    = $tenantEsc
        COVER_SUBTITLE = 'Zapis konfiguracji tenanta: tożsamość, urządzenia, usługi produktywności i ochrona informacji.'
        COVER_FACTS    = $coverFactsHtml
        COVER_NOTE     = 'Dokument przedstawia stan konfiguracji odczytany z Microsoft Graph oraz interfejsów administracyjnych Microsoft 365 w dniu generowania. Sekcje, których nie udało się odczytać z powodu brakujących uprawnień lub licencji, wymieniono w załączniku.'
        DASHBOARD      = $dashboardHtml
        TOC            = $tocHtml
        CHAPTERS       = $chaptersHtml
        FOOTER_LEFT    = "Dokumentacja Microsoft 365 - $tenantEsc"
        FOOTER_RIGHT   = "Wygenerowano automatycznie przez M365TenantReporter - $generatedAt"
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
