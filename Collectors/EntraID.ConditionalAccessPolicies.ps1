function Get-M365TRCAPolicySummary {
    param($Policy)
    $parts = New-Object System.Collections.Generic.List[string]

    $users = $Policy.conditions.users
    if ($users) {
        if ($users.includeUsers -contains 'All') { $parts.Add('użytkownicy: wszyscy') }
        elseif ($users.includeGroups -and @($users.includeGroups).Count -gt 0) { $parts.Add("użytkownicy: $(@($users.includeGroups).Count) grupa(y)") }
        elseif ($users.includeUsers -and @($users.includeUsers).Count -gt 0) { $parts.Add("użytkownicy: $(@($users.includeUsers).Count) wybranych") }
        if ($users.excludeUsers -and @($users.excludeUsers).Count -gt 0) { $parts.Add("wyjatki: $(@($users.excludeUsers).Count) użytkownik(ow)") }
    }

    $apps = $Policy.conditions.applications
    if ($apps) {
        if ($apps.includeApplications -contains 'All') { $parts.Add('aplikacje: wszystkie') }
        elseif ($apps.includeApplications -and @($apps.includeApplications).Count -gt 0) { $parts.Add("aplikacje: $(@($apps.includeApplications).Count) wybranych") }
    }

    $platforms = $Policy.conditions.platforms.includePlatforms
    if ($platforms -and @($platforms).Count -gt 0) { $parts.Add("platformy: $(@($platforms) -join ', ')") }

    $locations = $Policy.conditions.locations
    if ($locations -and $locations.includeLocations -and @($locations.includeLocations).Count -gt 0) {
        $parts.Add('warunek lokalizacji')
    }

    $grant = $Policy.grantControls
    if ($grant) {
        if (@($grant.builtInControls) -contains 'block') {
            $parts.Add('DZIAŁANIE: BLOKUJE dostęp')
        } elseif ($grant.builtInControls -and @($grant.builtInControls).Count -gt 0) {
            $op = if ($grant.operator -eq 'OR') { 'dowolne z' } else { 'wszystkie z' }
            $parts.Add("wymaga ($op): $(@($grant.builtInControls) -join ', ')")
        }
    }

    $session = $Policy.sessionControls
    if ($session) {
        if ($session.signInFrequency.isEnabled) { $parts.Add("częstotliwość logowania: co $($session.signInFrequency.value) $($session.signInFrequency.type)") }
        if ($session.persistentBrowser.isEnabled) { $parts.Add('kontrola trwałości przegladarki') }
    }

    if ($parts.Count -eq 0) { return '(brak szczegolowych warunkow do podsumowania)' }
    return ($parts -join '; ')
}

function Get-Collector_EntraID_ConditionalAccessPolicies {
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/identity/conditionalAccess/policies'
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Polityki Conditional Access' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Polityki Conditional Access' -Status 'empty' `
            -Description 'Polityki dostępu warunkowego (Conditional Access) skonfigurowane w Entra ID.'
    }
    $flat = $r.Data | ForEach-Object {
        [PSCustomObject]@{
            'Nazwa'       = $_.displayName
            'Stan'        = $_.state
            'Co robi'     = Get-M365TRCAPolicySummary -Policy $_
        }
    }
    New-M365TRCollectorResult -Component 'EntraID' -Section 'Polityki Conditional Access' `
        -Description 'Polityki dostępu warunkowego (Conditional Access) skonfigurowane w Entra ID.' -Status 'ok' -Data $flat
}
