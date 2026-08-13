$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'M365TenantReporter.psd1') -Force

Write-Output 'Module imported OK. Exported commands:'
Get-Command -Module M365TenantReporter | Select-Object -ExpandProperty Name | Sort-Object

Write-Output '--- Testing report model + HTML render with synthetic data (exercises the private chart helpers internally) ---'
function New-FakeResult {
    param($Component, $Section, $Status = 'ok', $Message = $null, $Description = '', $Data = @(), [switch]$Transpose)
    [PSCustomObject]@{
        Component = $Component; Section = $Section; Description = $Description
        Status = $Status; Message = $Message; Data = @($Data); Transpose = [bool]$Transpose
    }
}

$fakeResults = @(
    New-FakeResult -Component 'EntraID' -Section 'Organizacja' -Status 'ok' -Transpose -Data @([PSCustomObject]@{ Nazwa = 'Contoso Sp. z o.o.'; 'Domena podstawowa' = 'contoso.onmicrosoft.com' })
    New-FakeResult -Component 'EntraID' -Section 'Polityki Conditional Access' -Status 'ok' -Data @(
        [PSCustomObject]@{ Nazwa = 'Wymagaj MFA'; Stan = 'enabled' }
        [PSCustomObject]@{ Nazwa = 'Blokuj legacy auth'; Stan = 'enabled' }
        [PSCustomObject]@{ Nazwa = 'Test report-only'; Stan = 'enabledForReportingButNotEnforced' }
    )
    New-FakeResult -Component 'Intune' -Section 'Polityki zgodności' -Status 'ok' -Data @(
        [PSCustomObject]@{ Nazwa = 'Windows baseline'; Platforma = 'Windows10CompliancePolicy' }
        [PSCustomObject]@{ Nazwa = 'iOS baseline'; Platforma = 'iosCompliancePolicy' }
    )
    New-FakeResult -Component 'Intune' -Section 'Uprawnienia PIM' -Status 'skipped-license' -Message 'Tenant nie posiada wymaganej licencji (Entra ID P2 / Governance).'
    New-FakeResult -Component 'CloudPrint' -Section 'Konektory' -Status 'skipped-permission' -Message 'Brak zgody/uprawnienia w Microsoft Graph.'
    New-FakeResult -Component 'Windows365' -Section 'Obrazy urządzeń' -Status 'empty'
)

$fakeLogo = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII='
$model = New-M365TRReportModel -Results $fakeResults -TenantName 'Contoso Sp. z o.o. (TEST)' -LogoDataUri $fakeLogo
$outPath = Join-Path $PSScriptRoot 'Output\SmokeTest.html'
New-M365TRHtmlReport -Model $model -OutputPath $outPath | Out-Null

if (-not (Test-Path -LiteralPath $outPath)) { throw 'HTML report was not created.' }
$content = Get-Content -LiteralPath $outPath -Raw
if ($content -notmatch '<svg') { throw 'HTML report has no charts.' }
if ($content -notmatch 'Contoso') { throw 'HTML report missing tenant name.' }
if ($content -notmatch 'cover-logo') { throw 'HTML report missing logo when LogoDataUri was provided.' }
Write-Output "Smoke test OK. Report: $outPath ($('{0:N0}' -f $content.Length) chars)"
