function Start-M365TRDocumentation {
    <#
    .SYNOPSIS
    One-command pipeline: sign in (choosing which tenant, unless overridden), collect every
    section, build the report model, and render HTML + (best-effort) PDF.
    #>
    [CmdletBinding()]
    param(
        [string]$OutputDirectory = (Join-Path (Split-Path -Parent $PSScriptRoot) 'Output'),
        [string]$TenantId,
        [ValidateSet('pl', 'en')][string]$Language,
        [switch]$Interactive,
        [switch]$NonInteractive,
        [switch]$SkipPdf
    )

    $moduleRoot = Split-Path -Parent $PSScriptRoot

    # Brak jawnie podanego -Language: pytamy interaktywnie (tak jak Connect-M365TR pyta o
    # tenanta), chyba że to przebieg nienadzorowany (-NonInteractive) - wtedy domyślnie polski,
    # zeby zaplanowane/automatyczne uruchomienia nigdy nie utknely czekajac na Read-Host.
    if (-not $Language) {
        if ($NonInteractive) {
            $Language = 'pl'
        } else {
            Write-Host ''
            Write-Host 'W jakim języku przygotować dokumentację? / In which language should the documentation be prepared?'
            Write-Host '  1) Polski'
            Write-Host '  2) English'
            $choice = $null
            try { $choice = Read-Host 'Wybierz numer / choose a number [1]' } catch { $choice = $null }
            $Language = if ("$choice".Trim() -eq '2') { 'en' } else { 'pl' }
        }
    }

    Install-M365TRPrerequisites

    $context = Connect-M365TR -TenantId $TenantId -Interactive:$Interactive -NonInteractive:$NonInteractive
    $context | Add-Member -MemberType NoteProperty -Name Language -Value $Language -Force
    $results = Invoke-M365TRCollection -Context $context -ModuleRoot $moduleRoot

    # Exchange/Purview: osobny proces (patrz komentarz w Invoke-M365TRCollection.ps1) - zbiera
    # wyniki do pliku JSON, który tutaj wczytujemy i dołączamy do reszty. Przekazujemy TenantId
    # wybrany przez Connect-M365TR, żeby Collect-Exchange.ps1 uzyl poświadczeń dla TEGO SAMEGO
    # tenanta (a nie np. jedynego zapisanego, jeśli użytkownik wybral inny w menu).
    Write-Host 'Uruchamianie zbierania danych Exchange/Purview (osobny proces)...'
    $exoJsonPath = Join-Path ([System.IO.Path]::GetTempPath()) "m365tr-exo-$([guid]::NewGuid()).json"
    try {
        $exoArgs = @('-NoProfile', '-File', (Join-Path $moduleRoot 'Collect-Exchange.ps1'), '-ModuleRoot', $moduleRoot, '-OutputJsonPath', $exoJsonPath, '-Language', $Language)
        if ($context.TenantId) { $exoArgs += @('-TenantId', $context.TenantId) }
        # Bez przekierowania - komunikaty procesu (np. dlaczego polaczenie z Exchange Online się
        # nie powiodlo) mają być widoczne, nie ukryte. Wczesniej `2>&1 | Out-Null` je wyciszal,
        # a plik wynikowy jest tworzony (pusty) jeszcze PRZED próba polaczenia, więc samo
        # Test-Path nigdy nie wykrywalo nieudanego polaczenia - stąd sekcje Exchange/Purview
        # (21 z 64) mogly cicho zniknąc z raportu bez zadnego ostrzezenia.
        & pwsh @exoArgs
        $exoResults = @()
        if (Test-Path -LiteralPath $exoJsonPath) {
            # Collect-Exchange.ps1 zapisuje wyniki linia-po-linii (JSON Lines), nie jako jedna
            # duza tablica - to środowisko ma powtarzalna, niewyjasniona niestabilność po
            # załadowaniu ExchangeOnlineManagement, gdzie masowe przetwarzanie napisow pod
            # koniec skryptu zawodzi z "Argument types do not match" na losowych liniach.
            # Parsowanie linia-po-linii tutaj, w OSOBNYM już procesie, jest bezpieczne.
            $exoLines = Get-Content -LiteralPath $exoJsonPath | Where-Object { $_ -and $_.Trim() }
            $exoResults = foreach ($line in $exoLines) {
                try {
                    $r = $line | ConvertFrom-Json
                    if ($null -eq $r.Data) { $r.Data = @() }
                    elseif ($r.Data -isnot [array]) { $r.Data = @($r.Data) }
                    $r
                } catch {
                    Write-Warning "Nie udało się odczytać jednej linii wyniku Exchange/Purview: $($_.Exception.Message)"
                }
            }
        }
        if (@($exoResults).Count -gt 0) {
            $results = @($results) + @($exoResults)
        } else {
            Write-Warning 'Zbieranie Exchange/Purview nie zwróciło żadnej sekcji - najpewniej nie udało się połączyć (patrz komunikaty procesu powyżej: brak modułu/certyfikatu/konfiguracji). Sekcje Exchange/Purview zostaną pominięte w raporcie.'
        }
    } finally {
        Remove-Item -LiteralPath $exoJsonPath -ErrorAction SilentlyContinue
    }

    # Teams: osobny proces, ta sama logika co Exchange/Purview powyzej - modul MicrosoftTeams ma
    # własny zestaw zależności, który mogby kolidowac z MSAL.PS/ExchangeOnlineManagement gdyby
    # dzielil proces z ktoryms z nich.
    Write-Host 'Uruchamianie zbierania danych Teams (osobny proces)...'
    $teamsJsonPath = Join-Path ([System.IO.Path]::GetTempPath()) "m365tr-teams-$([guid]::NewGuid()).json"
    try {
        $teamsArgs = @('-NoProfile', '-File', (Join-Path $moduleRoot 'Collect-Teams.ps1'), '-ModuleRoot', $moduleRoot, '-OutputJsonPath', $teamsJsonPath, '-Language', $Language)
        if ($context.TenantId) { $teamsArgs += @('-TenantId', $context.TenantId) }
        & pwsh @teamsArgs
        $teamsResults = @()
        if (Test-Path -LiteralPath $teamsJsonPath) {
            $teamsLines = Get-Content -LiteralPath $teamsJsonPath | Where-Object { $_ -and $_.Trim() }
            $teamsResults = foreach ($line in $teamsLines) {
                try {
                    $r = $line | ConvertFrom-Json
                    if ($null -eq $r.Data) { $r.Data = @() }
                    elseif ($r.Data -isnot [array]) { $r.Data = @($r.Data) }
                    $r
                } catch {
                    Write-Warning "Nie udało się odczytać jednej linii wyniku Teams: $($_.Exception.Message)"
                }
            }
        }
        if (@($teamsResults).Count -gt 0) {
            $results = @($results) + @($teamsResults)
        } else {
            Write-Warning 'Zbieranie Teams nie zwróciło żadnej sekcji - najpewniej nie udało się połączyć (patrz komunikaty procesu powyżej: brak modułu/certyfikatu/konfiguracji). Sekcje Teams zostaną pominięte w raporcie.'
        }
    } finally {
        Remove-Item -LiteralPath $teamsJsonPath -ErrorAction SilentlyContinue
    }

    $orgResult = $results | Where-Object { $_.Component -eq 'EntraID' -and $_.Section -eq 'Organizacja' -and $_.Status -eq 'ok' } | Select-Object -First 1
    $tenantName = if ($orgResult -and $orgResult.Data[0].Nazwa) { $orgResult.Data[0].Nazwa }
                  elseif ($context.TenantDisplayName) { $context.TenantDisplayName }
                  else { 'Tenant M365' }

    Write-Host 'Pobieranie logo organizacji (Company Branding)...'
    $logoDataUri = Get-M365TRBrandingLogo -Context $context

    $model = New-M365TRReportModel -Results $results -TenantName $tenantName -LogoDataUri $logoDataUri -Language $Language

    if (-not (Test-Path -LiteralPath $OutputDirectory)) { New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null }
    $stamp = Get-Date -Format 'yyyyMMdd_HHmm'
    $safeTenant = ($tenantName -replace '[^\w\s-]', '' -replace '\s+', '_').Trim('_')
    if (-not $safeTenant) { $safeTenant = 'Tenant' }
    $htmlPath = Join-Path $OutputDirectory "${safeTenant}_M365Report_$stamp.html"
    $pdfPath = Join-Path $OutputDirectory "${safeTenant}_M365Report_$stamp.pdf"

    New-M365TRHtmlReport -Model $model -OutputPath $htmlPath | Out-Null

    $finalPdfPath = $null
    if (-not $SkipPdf) {
        $finalPdfPath = Export-M365TRReportPdf -HtmlPath $htmlPath -PdfPath $pdfPath
    }

    # Podpowiedz konsolowa (nie trafia do raportu) - informuje osobę uruchamiającą, że te
    # konkretne pominięcia mają dostępne, świadome rozwiązanie (Setup-AppPermissions.ps1), a nie
    # są tylko kolejnym "brak licencji/uprawnień" do zignorowania.
    $skippedCompliance = @($results | Where-Object { $_.Component -eq 'Purview' -and $_.Status -eq 'skipped-permission' -and $_.Message -match 'Get-InsiderRiskPolicy|Get-ComplianceCase|Get-UnifiedAuditLogRetentionPolicy' })
    if ($skippedCompliance.Count -gt 0) {
        Write-Host ''
        Write-Host ("Uwaga: {0} sekcji Purview (Insider Risk / eDiscovery / retencja audytu) zostało pominiętych - to konto ma tylko rolę Global Reader." -f $skippedCompliance.Count)
        Write-Host 'Aby je odblokować, uruchom ponownie Setup-AppPermissions.ps1 dla tego tenanta i zgódź się na rozszerzenie uprawnień o rolę Compliance Administrator, gdy zapyta.'
    }

    [PSCustomObject]@{
        HtmlPath = $htmlPath
        PdfPath  = $finalPdfPath
        Model    = $model
        Results  = $results
    }
}
