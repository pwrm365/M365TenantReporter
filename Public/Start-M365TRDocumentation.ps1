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

    # SharePoint (poziom administracyjny, PnP.PowerShell): osobny proces, ta sama logika co
    # Exchange/Teams powyzej. To krok OPCJONALNY (patrz Add-M365TRSharePointAdminAccess) - dla
    # tenantow, które go nie skonfigurowały, Connect-PnPOnline (uwierzytelnianie certyfikatem)
    # samo w sobie się powodzi, ale każde wywołanie cmdletu zwraca 401 Unauthorized (brak
    # Sites.FullControl.All) - klasyfikowane jako skipped-permission, nie error (patrz
    # Invoke-M365TREXOCommand). Sekcje więc się pojawiają, tylko jako pominięte, nie znikają.
    Write-Host 'Uruchamianie zbierania danych SharePoint (poziom administracyjny, osobny proces)...'
    $spoJsonPath = Join-Path ([System.IO.Path]::GetTempPath()) "m365tr-spo-$([guid]::NewGuid()).json"
    try {
        $spoArgs = @('-NoProfile', '-File', (Join-Path $moduleRoot 'Collect-SharePointAdmin.ps1'), '-ModuleRoot', $moduleRoot, '-OutputJsonPath', $spoJsonPath, '-Language', $Language)
        if ($context.TenantId) { $spoArgs += @('-TenantId', $context.TenantId) }
        & pwsh @spoArgs
        $spoResults = @()
        if (Test-Path -LiteralPath $spoJsonPath) {
            $spoLines = Get-Content -LiteralPath $spoJsonPath | Where-Object { $_ -and $_.Trim() }
            $spoResults = foreach ($line in $spoLines) {
                try {
                    $r = $line | ConvertFrom-Json
                    if ($null -eq $r.Data) { $r.Data = @() }
                    elseif ($r.Data -isnot [array]) { $r.Data = @($r.Data) }
                    $r
                } catch {
                    Write-Warning "Nie udało się odczytać jednej linii wyniku SharePoint (admin): $($_.Exception.Message)"
                }
            }
        }
        if (@($spoResults).Count -gt 0) {
            $results = @($results) + @($spoResults)
        }
        # Brak wyniku tutaj (proces nie zdołał się nawet połączyć - np. modul PnP.PowerShell nie
        # zainstalowany) NIE jest ostrzegane jak przy Exchange/Teams, tylko cicho pomijane - to
        # krok opcjonalny. Podpowiedz o tym, jak go wlaczyc, jest wyswietlana pod koniec.
    } finally {
        Remove-Item -LiteralPath $spoJsonPath -ErrorAction SilentlyContinue
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
        if ($Language -eq 'en') {
            Write-Host ("Note: {0} Purview sections (Insider Risk / eDiscovery / audit retention) were skipped - this account only has the Global Reader role." -f $skippedCompliance.Count)
            Write-Host 'To unlock them, re-run Setup-AppPermissions.ps1 for this tenant and agree to the Compliance Administrator role grant when asked.'
        } else {
            Write-Host ("Uwaga: {0} sekcji Purview (Insider Risk / eDiscovery / retencja audytu) zostało pominiętych - to konto ma tylko rolę Global Reader." -f $skippedCompliance.Count)
            Write-Host 'Aby je odblokować, uruchom ponownie Setup-AppPermissions.ps1 dla tego tenanta i zgódź się na rozszerzenie uprawnień o rolę Compliance Administrator, gdy zapyta.'
        }
    }
    $spoAdminSections = @('Witryna startowa (Home Site)', 'Witryny Hub', 'Ustawienia SharePoint (poziom administracyjny)')
    $skippedSpoAdmin = @($results | Where-Object { $_.Component -eq 'SharePoint' -and $_.Section -in $spoAdminSections -and $_.Status -in @('skipped-permission', 'error') })
    if ($skippedSpoAdmin.Count -gt 0) {
        Write-Host ''
        if ($Language -eq 'en') {
            Write-Host ("Note: {0} SharePoint administrative-level sections (home site, hub sites, idle session settings) were skipped - this optional access is not configured for this tenant." -f $skippedSpoAdmin.Count)
            Write-Host 'To enable it, re-run Setup-AppPermissions.ps1 for this tenant and agree to the SharePoint administrative access grant when asked.'
        } else {
            Write-Host ("Uwaga: {0} sekcji SharePoint na poziomie administracyjnym (witryna startowa, witryny Hub, ustawienia bezczynności) zostało pominiętych - ten opcjonalny dostęp nie jest skonfigurowany dla tego tenanta." -f $skippedSpoAdmin.Count)
            Write-Host 'Aby go włączyć, uruchom ponownie Setup-AppPermissions.ps1 dla tego tenanta i zgódź się na rozszerzenie uprawnień o dostęp administracyjny SharePoint, gdy zapyta.'
        }
    }

    [PSCustomObject]@{
        HtmlPath = $htmlPath
        PdfPath  = $finalPdfPath
        Model    = $model
        Results  = $results
    }
}
