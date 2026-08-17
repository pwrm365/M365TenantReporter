function Get-Collector_EntraID_ConditionalAccessPolicies {
    <#
    .SYNOPSIS
    One detailed record per Conditional Access policy (Podstawowe/Ustawienia) - full condition
    breakdown (users/groups, cloud apps, platforms, locations, risk levels), grant controls and
    session controls, instead of a single condensed summary sentence.
    #>
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/identity/conditionalAccess/policies'
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Polityki Conditional Access' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Polityki Conditional Access' -Status 'empty' `
            -Description 'Polityki dostępu warunkowego (Conditional Access) skonfigurowane w Entra ID.'
    }

    $stateLabels = @{
        enabled                            = 'Włączona'
        disabled                           = 'Wyłączona'
        enabledForReportingButNotEnforced  = 'Tylko raportowanie (report-only)'
    }

    $records = foreach ($p in $r.Data) {
        $basicRows = @(
            [PSCustomObject]@{ Ustawienie = 'Nazwa'; Wartość = $p.displayName }
            [PSCustomObject]@{ Ustawienie = 'Stan'; Wartość = $(if ($stateLabels.ContainsKey($p.state)) { $stateLabels[$p.state] } else { $p.state }) }
            [PSCustomObject]@{ Ustawienie = 'Utworzono'; Wartość = $p.createdDateTime }
            [PSCustomObject]@{ Ustawienie = 'Zmodyfikowano'; Wartość = $p.modifiedDateTime }
        ) | Where-Object { $_.Wartość }

        $settingsRows = @(Get-M365TRConditionalAccessRows -Context $Context -Policy $p)

        New-M365TRDetailRecord -Name $p.displayName -Tables @(
            (New-M365TRDetailTable -Title 'Podstawowe' -Rows $basicRows)
            (New-M365TRDetailTable -Title 'Ustawienia' -Rows $settingsRows)
        )
    }

    New-M365TRCollectorResult -Component 'EntraID' -Section 'Polityki Conditional Access' `
        -Description 'Polityki dostępu warunkowego (Conditional Access) skonfigurowane w Entra ID.' -Status 'ok' -Records -Data $records
}
