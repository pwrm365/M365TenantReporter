function Get-Collector_Purview_InsiderRiskPolicies {
    <#
    .SYNOPSIS
    Zasady zarządzania ryzykiem wewnętrznym (Insider Risk Management) w Microsoft Purview - wykrywanie
    potencjalnie ryzykownych działań pracowników (eksfiltracja danych, naruszenia zasad). Funkcja
    wymaga licencji E5/Compliance - jej brak jest normalnym stanem w mniejszych organizacjach i
    pojawi się jako pusta/pominięta sekcja, nie błąd. Właściwości tego cmdletu nie są w pełni
    ustandaryzowane w dokumentacji Microsoft, dlatego pokazujemy pełny zrzut - nic nie jest
    świadomie ukrywane, nawet jeśli etykieta nie jest jeszcze wyselekcjonowana.
    #>
    param([Parameter(Mandatory)]$Context)
    $lang = Get-M365TRLanguage -Context $Context
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-InsiderRiskPolicy }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Purview' -Section 'Zasady zarządzania ryzykiem wewnętrznym (Insider Risk)' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        $emptyDescription = if ($lang -eq 'en') { 'Insider Risk Management policies configured in Microsoft Purview (detecting potentially risky employee activity).' } else { 'Zasady zarządzania ryzykiem wewnętrznym (Insider Risk Management) skonfigurowane w Microsoft Purview.' }
        return New-M365TRCollectorResult -Component 'Purview' -Section 'Zasady zarządzania ryzykiem wewnętrznym (Insider Risk)' -Status 'empty' -Description $emptyDescription
    }

    $excludeProps = @('Identity', 'Id', 'Guid', 'DistinguishedName', 'ExchangeVersion', 'ObjectCategory', 'ObjectClass', 'OrganizationalUnitRoot', 'OriginatingServer', 'IsValid', 'ObjectState', 'RunspaceId', 'WhenChanged', 'WhenChangedUTC', 'WhenCreated', 'WhenCreatedUTC', 'ImmutableId', 'Name', 'PSComputerName', 'PSShowComputerName')

    $records = $r.Data | ForEach-Object {
        $settingsRows = @(ConvertTo-M365TRLabeledRows -InputObject $_ -ExcludeProperties $excludeProps -Language $lang)
        $recordName = if ($_.Name) { "$($_.Name)" } else { "$($_.Identity)" }
        New-M365TRDetailRecord -Name $recordName -Tables @(
            (New-M365TRDetailTable -Title 'Ustawienia' -Rows $settingsRows)
        )
    }

    $description = if ($lang -eq 'en') {
        'Insider Risk Management policies configured in Microsoft Purview - detecting potentially risky employee activity (data exfiltration, policy violations). Requires an E5/Compliance license.'
    } else {
        'Zasady zarządzania ryzykiem wewnętrznym (Insider Risk Management) skonfigurowane w Microsoft Purview - wykrywanie potencjalnie ryzykownych działań pracowników. Wymaga licencji E5/Compliance.'
    }
    New-M365TRCollectorResult -Component 'Purview' -Section 'Zasady zarządzania ryzykiem wewnętrznym (Insider Risk)' -Description $description -Status 'ok' -Records -Data $records
}
