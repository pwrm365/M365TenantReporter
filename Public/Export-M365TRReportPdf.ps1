function Export-M365TRReportPdf {
    <#
    .SYNOPSIS
    Converts the HTML report to PDF via headless Microsoft Edge - no extra installs needed
    on Windows 11. Best-effort: if Edge isn't found or the conversion fails, this only warns -
    the HTML report is always the source of truth and is never blocked by this step.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$HtmlPath,
        [Parameter(Mandatory)][string]$PdfPath
    )

    $edgeCandidates = @(
        (Get-Command msedge -ErrorAction SilentlyContinue).Source
        "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe"
        "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }
    $edge = $edgeCandidates | Select-Object -First 1

    if (-not $edge) {
        Write-Warning 'Nie znaleziono Microsoft Edge - pomijam eksport do PDF. Raport HTML jest kompletny.'
        return $null
    }

    $absoluteHtml = (Resolve-Path -LiteralPath $HtmlPath).Path
    $fileUri = 'file:///' + ($absoluteHtml -replace '\\', '/')
    $dir = Split-Path -Parent $PdfPath
    if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

    $arguments = @(
        '--headless=new'
        '--disable-gpu'
        '--no-pdf-header-footer'
        "--print-to-pdf=$PdfPath"
        '--virtual-time-budget=30000'
        $fileUri
    )

    try {
        Start-Process -FilePath $edge -ArgumentList $arguments -Wait -WindowStyle Hidden
    } catch {
        Write-Warning "Eksport do PDF nie powiodl się: $($_.Exception.Message)"
        return $null
    }

    if ((Test-Path -LiteralPath $PdfPath) -and (Get-Item -LiteralPath $PdfPath).Length -gt 0) {
        Write-Host "PDF zapisany: $PdfPath"
        return $PdfPath
    }
    Write-Warning 'Plik PDF nie został utworzony. Raport HTML jest nadal dostępny.'
    return $null
}
