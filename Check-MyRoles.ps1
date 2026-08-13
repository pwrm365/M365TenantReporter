$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'M365TenantReporter.psd1') -Force

$context = Connect-M365TR
$module = Get-Module M365TenantReporter
$r = & $module { param($ctx, $path) Invoke-M365TRGraphRequest -Context $ctx -Path $path } $context '/me/transitiveMemberOf/microsoft.graph.directoryRole'
if (-not $r.Success) {
    Write-Output "BŁĄD: $($r.Message)"
} else {
    Write-Output "Role katalogowe przypisane do zalogowanego konta:"
    $r.Data | ForEach-Object { Write-Output " - $($_.displayName)" }
    if ($r.Data.Count -eq 0) { Write-Output "(brak ról katalogowych - konto może miec dostęp tylko przez grupy z przypisana rola PIM/eligibility, nie widoczne tutaj jako aktywne)" }
}
