#requires -Version 7.0
<#
.SYNOPSIS
Runs ONLY the Exchange/Purview collectors, in their own process. ExchangeOnlineManagement
bundles its own Microsoft.Identity.Client.dll which conflicts (assembly version mismatch)
with the one MSAL.PS loads for Graph auth in the main process - the documented workaround
is process isolation, so this script never touches MSAL.PS/Connect-M365TR at all.

Writes each collector result as its own JSON line (JSON Lines format) to OutputJsonPath
IMMEDIATELY after it's collected, rather than accumulating everything in memory and
serializing it all at the very end. This environment exhibits a reproducible but unexplained
instability after loading ExchangeOnlineManagement/Connect-IPPSSession, where ordinary string
operations (interpolation, [string] casts, even ConvertTo-Json) throw "Argument types do not
match" - the failure point moves to a different, otherwise-unremarkable line each time the
prior one is patched around, and it worsens the more accumulated result-processing happens late
in the script. Serializing immediately, one small object at a time, right where the data is
freshest, avoids whatever this is instead of chasing it further.
#>
[CmdletBinding()]
param(
    [string]$ModuleRoot = $PSScriptRoot,
    [Parameter(Mandatory)][string]$OutputJsonPath,
    [string]$TenantId
)

Import-Module (Join-Path $ModuleRoot 'M365TenantReporter.psd1') -Force

# New-M365TRCollectorResult/Invoke-M365TREXOCommand są prywatne funkcje modułu, niewidoczne z
# tego skryptu przez Import-Module - dot-source'ujemy je bezpośrednio tutaj, żeby kolektory
# (tez dot-sourcowane w tym samym, plaskim scope) widzialy je zwyklym mechanizmem PowerShella.
. (Join-Path $ModuleRoot 'Private\New-M365TRCollectorResult.ps1')
. (Join-Path $ModuleRoot 'Private\Invoke-M365TREXOCommand.ps1')

if (Test-Path -LiteralPath $OutputJsonPath) { Remove-Item -LiteralPath $OutputJsonPath -Force }
New-Item -ItemType File -Path $OutputJsonPath -Force | Out-Null

$connected = Connect-M365TRExchange -TenantId $TenantId
if (-not $connected) {
    return
}

try {
    $collectorFiles = Get-ChildItem -Path (Join-Path $ModuleRoot 'Collectors') -Filter '*.ps1' -File |
        Where-Object { $_.BaseName -match '^(Exchange|Purview)\.' } | Sort-Object Name

    foreach ($file in $collectorFiles) {
        $parts = $file.BaseName -split '\.'
        $component = $parts[0]
        $section = $parts[1]
        $functionName = "Get-Collector_${component}_${section}"
        try {
            . $file.FullName
            $fn = Get-Command $functionName -ErrorAction Stop
            $result = & $fn -Context ([PSCustomObject]@{})
            if (-not $result) {
                $result = New-M365TRCollectorResult -Component $component -Section $section -Status 'error' -Message 'Kolektor nie zwrocil zadnego wyniku.'
            }
        } catch {
            $result = New-M365TRCollectorResult -Component $component -Section $section -Status 'error' -Message "Nieoczekiwany błąd kolektora: $($_.Exception.Message)"
        }

        try {
            $line = Microsoft.PowerShell.Utility\ConvertTo-Json -InputObject $result -Depth 6 -Compress -ErrorAction Stop
            Add-Content -LiteralPath $OutputJsonPath -Value $line -Encoding UTF8
        } catch {
            $fallback = Microsoft.PowerShell.Utility\ConvertTo-Json -Compress -InputObject @{
                Component = $component; Section = $section; Description = ''
                Status = 'error'; Message = 'Wynik zebrany, ale nie dalo się go od razu zapisać.'
                Data = @(); Transpose = $false
            }
            Add-Content -LiteralPath $OutputJsonPath -Value $fallback -Encoding UTF8
        }
    }
} finally {
    try { Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue | Out-Null } catch {}
}
