function Start-M365TRDocumentation {
    <#
    .SYNOPSIS
    One-command pipeline: sign in (choosing which tenant, unless overridden), collect every
    section, build the report model, and render HTML + (best-effort) PDF.
    #>
    [CmdletBinding()]
    param(
        [string]$OutputDirectory = 'C:\data\M365TenantReporter\Output',
        [string]$TenantId,
        [switch]$Interactive,
        [switch]$NonInteractive,
        [switch]$SkipPdf
    )

    $moduleRoot = Split-Path -Parent $PSScriptRoot

    Install-M365TRPrerequisites

    $context = Connect-M365TR -TenantId $TenantId -Interactive:$Interactive -NonInteractive:$NonInteractive
    $results = Invoke-M365TRCollection -Context $context -ModuleRoot $moduleRoot

    # Exchange/Purview: osobny proces (patrz komentarz w Invoke-M365TRCollection.ps1) - zbiera
    # wyniki do pliku JSON, który tutaj wczytujemy i dołączamy do reszty. Przekazujemy TenantId
    # wybrany przez Connect-M365TR, żeby Collect-Exchange.ps1 uzyl poświadczeń dla TEGO SAMEGO
    # tenanta (a nie np. jedynego zapisanego, jeśli użytkownik wybral inny w menu).
    Write-Host 'Uruchamianie zbierania danych Exchange/Purview (osobny proces)...'
    $exoJsonPath = Join-Path ([System.IO.Path]::GetTempPath()) "m365tr-exo-$([guid]::NewGuid()).json"
    try {
        $exoArgs = @('-NoProfile', '-File', (Join-Path $moduleRoot 'Collect-Exchange.ps1'), '-ModuleRoot', $moduleRoot, '-OutputJsonPath', $exoJsonPath)
        if ($context.TenantId) { $exoArgs += @('-TenantId', $context.TenantId) }
        & pwsh @exoArgs 2>&1 | Out-Null
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
            if (@($exoResults).Count -gt 0) {
                $results = @($results) + @($exoResults)
            }
        } else {
            Write-Warning 'Zbieranie Exchange/Purview nie wygenerowalo wyniku - sekcje te zostaną pominięte w raporcie.'
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
        $teamsArgs = @('-NoProfile', '-File', (Join-Path $moduleRoot 'Collect-Teams.ps1'), '-ModuleRoot', $moduleRoot, '-OutputJsonPath', $teamsJsonPath)
        if ($context.TenantId) { $teamsArgs += @('-TenantId', $context.TenantId) }
        & pwsh @teamsArgs 2>&1 | Out-Null
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
            if (@($teamsResults).Count -gt 0) {
                $results = @($results) + @($teamsResults)
            }
        } else {
            Write-Warning 'Zbieranie Teams nie wygenerowało wyniku - sekcje te zostaną pominięte w raporcie.'
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

    $model = New-M365TRReportModel -Results $results -TenantName $tenantName -LogoDataUri $logoDataUri

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

    [PSCustomObject]@{
        HtmlPath = $htmlPath
        PdfPath  = $finalPdfPath
        Model    = $model
        Results  = $results
    }
}
