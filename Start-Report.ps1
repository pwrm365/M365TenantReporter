#requires -Version 7.0
[CmdletBinding()]
param(
    [string]$OutputDirectory = 'C:\data\M365TenantReporter\Output',
    [string]$TenantId,
    [switch]$Interactive,
    [switch]$NonInteractive,
    [switch]$SkipPdf
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'M365TenantReporter.psd1') -Force

$result = Start-M365TRDocumentation -OutputDirectory $OutputDirectory -TenantId $TenantId -Interactive:$Interactive -NonInteractive:$NonInteractive -SkipPdf:$SkipPdf

Write-Host ''
Write-Host "Raport HTML: $($result.HtmlPath)"
if ($result.PdfPath) { Write-Host "Raport PDF:  $($result.PdfPath)" }
Write-Host "Sekcje: $($result.Model.TotalSections) | OK: $($result.Model.Health.ok) | Puste: $($result.Model.Health.empty) | Pominięte: $($result.Model.Health.'skipped-permission' + $result.Model.Health.'skipped-license') | Błędy: $($result.Model.Health.error)"
