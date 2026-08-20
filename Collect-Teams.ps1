#requires -Version 7.0
<#
.SYNOPSIS
Runs ONLY the Teams collectors, in their own process - same isolation reasoning as
Collect-Exchange.ps1: MicrosoftTeams module ships its own dependency graph that could
conflict with MSAL.PS (Graph auth) or ExchangeOnlineManagement if loaded in the same process,
so each gets a fully separate process. Writes each collector result as its own JSON line
(JSON Lines format) to OutputJsonPath immediately after it's collected.
#>
[CmdletBinding()]
param(
    [string]$ModuleRoot = $PSScriptRoot,
    [Parameter(Mandatory)][string]$OutputJsonPath,
    [string]$TenantId,
    [ValidateSet('pl', 'en')][string]$Language = 'pl'
)

Import-Module (Join-Path $ModuleRoot 'M365TenantReporter.psd1') -Force

# Prywatne funkcje modułu, niewidoczne z tego skryptu przez Import-Module - dot-source'ujemy je
# bezpośrednio tutaj, żeby kolektory (też dot-sourcowane w tym samym, płaskim scope) widziały je
# zwykłym mechanizmem PowerShella. Get-M365TRLanguage jest potrzebna kolektorom Teams do
# budowania dwujęzycznych podsumowan ("Co robi").
. (Join-Path $ModuleRoot 'Private\New-M365TRCollectorResult.ps1')
. (Join-Path $ModuleRoot 'Private\Invoke-M365TREXOCommand.ps1')
. (Join-Path $ModuleRoot 'Private\Get-M365TRLanguage.ps1')
. (Join-Path $ModuleRoot 'Private\New-M365TRDetailRecord.ps1')
. (Join-Path $ModuleRoot 'Private\ConvertTo-M365TRHumanizedName.ps1')
. (Join-Path $ModuleRoot 'Private\ConvertTo-M365TRLabeledRows.ps1')

if (Test-Path -LiteralPath $OutputJsonPath) { Remove-Item -LiteralPath $OutputJsonPath -Force }
New-Item -ItemType File -Path $OutputJsonPath -Force | Out-Null

$connected = Connect-M365TRTeams -TenantId $TenantId
if (-not $connected) {
    return
}

try {
    $collectorFiles = Get-ChildItem -Path (Join-Path $ModuleRoot 'Collectors') -Filter '*.ps1' -File |
        Where-Object { $_.BaseName -match '^Teams\.' } | Sort-Object Name

    foreach ($file in $collectorFiles) {
        $parts = $file.BaseName -split '\.'
        $component = $parts[0]
        $section = $parts[1]
        $functionName = "Get-Collector_${component}_${section}"
        # Do 2 proby - to samo srodowisko wykazuje sporadyczna, nie-deterministyczna
        # niestabilnosc jak w Collect-Exchange.ps1 (identyczny kod czasem rzuca wyjatek, czasem nie).
        $lastError = $null
        $result = $null
        for ($attempt = 1; $attempt -le 2; $attempt++) {
            try {
                . $file.FullName
                $fn = Get-Command $functionName -ErrorAction Stop
                $result = & $fn -Context ([PSCustomObject]@{ Language = $Language })
                if (-not $result) {
                    $result = New-M365TRCollectorResult -Component $component -Section $section -Status 'error' -Message 'Kolektor nie zwrócił żadnego wyniku.'
                }
                $lastError = $null
                break
            } catch {
                $lastError = $_
            }
        }
        if ($lastError) {
            $result = New-M365TRCollectorResult -Component $component -Section $section -Status 'error' -Message "Nieoczekiwany błąd kolektora: $($lastError.Exception.Message)"
        }

        try {
            $line = Microsoft.PowerShell.Utility\ConvertTo-Json -InputObject $result -Depth 6 -Compress -ErrorAction Stop
            Add-Content -LiteralPath $OutputJsonPath -Value $line -Encoding UTF8
        } catch {
            $fallback = Microsoft.PowerShell.Utility\ConvertTo-Json -Compress -InputObject @{
                Component = $component; Section = $section; Description = ''
                Status = 'error'; Message = 'Wynik zebrany, ale nie dało się go od razu zapisać.'
                Data = @(); Transpose = $false
            }
            Add-Content -LiteralPath $OutputJsonPath -Value $fallback -Encoding UTF8
        }
    }
} finally {
    try { Disconnect-MicrosoftTeams -Confirm:$false -ErrorAction SilentlyContinue | Out-Null } catch {}
}
