#requires -Version 7.0
[CmdletBinding()]
param(
    [string]$OutputDirectory = (Join-Path $PSScriptRoot 'Output'),
    [string]$TenantId,
    [ValidateSet('pl', 'en')][string]$Language,
    [switch]$Interactive,
    [switch]$NonInteractive,
    [switch]$SkipPdf
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'M365TenantReporter.psd1') -Force

# -Language nie ma tu domyslnej wartosci celowo: gdy nie podano go jawnie, Start-M365TRDocumentation
# samo o niego zapyta (chyba ze -NonInteractive) - podanie tu "pl" na sztywno zablokowaloby to pytanie.
$docArgs = @{
    OutputDirectory = $OutputDirectory
    TenantId        = $TenantId
    Interactive     = $Interactive
    NonInteractive  = $NonInteractive
    SkipPdf         = $SkipPdf
}
if ($Language) { $docArgs.Language = $Language }
$result = Start-M365TRDocumentation @docArgs

Write-Host ''
Write-Host "Raport HTML: $($result.HtmlPath)"
if ($result.PdfPath) { Write-Host "Raport PDF:  $($result.PdfPath)" }
Write-Host "Sekcje: $($result.Model.TotalSections) | OK: $($result.Model.Health.ok) | Puste: $($result.Model.Health.empty) | Pominięte: $($result.Model.Health.'skipped-permission' + $result.Model.Health.'skipped-license') | Błędy: $($result.Model.Health.error)"
