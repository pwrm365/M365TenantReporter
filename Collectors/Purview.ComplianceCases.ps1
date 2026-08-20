function Get-Collector_Purview_ComplianceCases {
    <#
    .SYNOPSIS
    Sprawy zgodności/eDiscovery (Compliance Cases) w Microsoft Purview - dochodzenia, przeglądy
    prawne i sprawy eDiscovery skonfigurowane w tenancie, wraz z ich stanem. Puste dla większości
    tenantów, dopóki nie zaistnieje potrzeba dochodzenia/postępowania - to normalny stan.
    #>
    param([Parameter(Mandatory)]$Context)
    $lang = Get-M365TRLanguage -Context $Context
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-ComplianceCase }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Purview' -Section 'Sprawy zgodności i eDiscovery' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        $emptyDescription = if ($lang -eq 'en') { 'Compliance/eDiscovery cases configured in Microsoft Purview.' } else { 'Sprawy zgodności/eDiscovery skonfigurowane w Microsoft Purview.' }
        return New-M365TRCollectorResult -Component 'Purview' -Section 'Sprawy zgodności i eDiscovery' -Status 'empty' -Description $emptyDescription
    }

    $flat = $r.Data | ForEach-Object {
        [PSCustomObject]@{
            'Nazwa'      = $_.Name
            'Typ'        = "$($_.CaseType)"
            'Status'     = "$($_.Status)"
            'Utworzono'  = if ($_.CreatedDateTime) { ([datetime]$_.CreatedDateTime).ToString('dd.MM.yyyy') } else { '' }
            'Opis'       = "$($_.Description)"
        }
    }

    $description = if ($lang -eq 'en') {
        'Compliance/eDiscovery cases configured in Microsoft Purview - investigations, legal holds and eDiscovery matters, with their current status.'
    } else {
        'Sprawy zgodności/eDiscovery skonfigurowane w Microsoft Purview - dochodzenia, przeglądy prawne i sprawy eDiscovery wraz z ich aktualnym stanem.'
    }
    New-M365TRCollectorResult -Component 'Purview' -Section 'Sprawy zgodności i eDiscovery' -Description $description -Status 'ok' -Data $flat
}
