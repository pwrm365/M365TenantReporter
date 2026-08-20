function Invoke-M365TRCollection {
    <#
    .SYNOPSIS
    Runs every auto-discovered collector against the tenant. A single collector throwing an
    unhandled exception is caught here too (defense in depth on top of Invoke-M365TRGraphRequest
    never throwing) - one bad section becomes one 'error' result, the run always finishes.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)][string]$ModuleRoot
    )

    # Exchange/Purview i Teams kolektory są uruchamiane osobno (Collect-Exchange.ps1 /
    # Collect-Teams.ps1, każdy we wlasnym procesie) - ExchangeOnlineManagement i MicrosoftTeams
    # laduja własne, niezgodne wersje zależności, które koliduja z MSAL.PS uzywanym tutaj do
    # logowania Graph w tym samym procesie.
    $collectors = Get-M365TRCollectorFiles -ModuleRoot $ModuleRoot | Where-Object { $_.Component -notin @('Exchange', 'Purview', 'Teams') }
    $results = @()
    $i = 0
    foreach ($c in $collectors) {
        $i++
        Write-Host ("[{0}/{1}] {2} / {3}" -f $i, $collectors.Count, $c.Component, $c.Section) -NoNewline

        # Do 2 proby: obserwowana w tym srodowisku niewyjasniona, nie-deterministyczna
        # niestabilnosc (patrz komentarz w Collect-Exchange.ps1) sporadycznie objawia sie jako
        # "Argument types do not match" przy identycznym kodzie i danych - ten sam kolektor
        # czasem przechodzi, czasem nie. Retry jest tania, uczciwa odpowiedz na cos co jest
        # potwierdzone jako sporadyczne, a nie deterministyczny blad logiki.
        $lastError = $null
        $result = $null
        for ($attempt = 1; $attempt -le 2; $attempt++) {
            try {
                . $c.Path
                $fn = Get-Command $c.FunctionName -ErrorAction Stop
                $result = & $fn -Context $Context
                if (-not $result) {
                    $result = New-M365TRCollectorResult -Component $c.Component -Section $c.Section `
                        -Status 'error' -Message 'Kolektor nie zwrocil zadnego wyniku.'
                }
                $lastError = $null
                break
            } catch {
                $lastError = $_
            }
        }
        if ($lastError) {
            $result = New-M365TRCollectorResult -Component $c.Component -Section $c.Section `
                -Status 'error' -Message "Nieoczekiwany błąd kolektora: $($lastError.Exception.Message)"
        }

        $results += $result
        $label = switch ($result.Status) {
            'ok'                  { 'OK' }
            'empty'               { 'PUSTE' }
            'skipped-permission'  { 'POMINIĘTO (uprawnienia)' }
            'skipped-license'     { 'POMINIĘTO (licencja)' }
            default               { 'BŁĄD' }
        }
        Write-Host ("  -> {0}{1}" -f $label, $(if ($result.Message) { ": $($result.Message)" } else { '' }))
    }

    return $results
}
