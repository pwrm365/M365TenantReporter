function Get-M365TRSharingPolicySummary {
    param($Policy, [ValidateSet('pl', 'en')][string]$Language = 'pl')
    $parts = New-Object System.Collections.Generic.List[string]

    foreach ($entry in @($Policy.Domains)) {
        if (-not $entry) { continue }
        $splitIdx = $entry.IndexOf(':')
        if ($splitIdx -lt 0) { $parts.Add([string]$entry); continue }
        $scope = $entry.Substring(0, $splitIdx)
        $levels = $entry.Substring($splitIdx + 1)
        if ($Language -eq 'en') {
            if ($scope -eq 'Anonymous') { $parts.Add("ANONYMOUS/public sharing: $levels") }
            elseif ($scope -eq '*') { $parts.Add("Sharing for all external domains (*): $levels") }
            else { $parts.Add("Sharing for domain $($scope): $levels") }
        } else {
            if ($scope -eq 'Anonymous') { $parts.Add("Udostępnianie ANONIMOWE/publiczne: $levels") }
            elseif ($scope -eq '*') { $parts.Add("Udostępnianie dla wszystkich domen zewnętrznych (*): $levels") }
            else { $parts.Add("Udostępnianie dla domeny $($scope): $levels") }
        }
    }

    if ($parts.Count -eq 0) {
        return $(if ($Language -eq 'en') { '(no sharing domains defined)' } else { '(brak zdefiniowanych domen udostępniania)' })
    }
    return ($parts -join '; ')
}

function Get-Collector_Exchange_SharingPolicies {
    param([Parameter(Mandatory)]$Context)
    $lang = Get-M365TRLanguage -Context $Context
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-SharingPolicy }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Zasady udostępniania (Sharing Policies)' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Zasady udostępniania (Sharing Policies)' -Status 'empty' `
            -Description 'Zasady udostępniania kalendarza i danych skrzynek pocztowych skonfigurowane w Exchange Online.'
    }
    $flat = $r.Data | ForEach-Object {
        [PSCustomObject]@{
            'Nazwa'    = $_.Name
            'Domyślna' = $_.Default
            'Włączona' = $_.Enabled
            'Co robi'  = Get-M365TRSharingPolicySummary -Policy $_ -Language $lang
        }
    }
    New-M365TRCollectorResult -Component 'Exchange' -Section 'Zasady udostępniania (Sharing Policies)' `
        -Description 'Zasady udostępniania kalendarza i danych skrzynek pocztowych skonfigurowane w Exchange Online.' -Status 'ok' -Data $flat
}
