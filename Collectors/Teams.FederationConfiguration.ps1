function Get-Collector_Teams_FederationConfiguration {
    <#
    .SYNOPSIS
    Ogólnotenantowa konfiguracja federacji Microsoft Teams: czy komunikacja z użytkownikami spoza
    organizacji (inne organizacje Teams, konta prywatne Teams/Skype) jest dozwolona, oraz jakie
    domeny są jawnie dozwolone/zablokowane.
    #>
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-CsTenantFederationConfiguration }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Teams' -Section 'Federacja z innymi organizacjami' -Status $r.Status -Message $r.Message
    }
    $cfg = $r.Data | Select-Object -First 1
    if (-not $cfg) {
        return New-M365TRCollectorResult -Component 'Teams' -Section 'Federacja z innymi organizacjami' -Status 'empty' `
            -Description 'Ogólnotenantowa konfiguracja federacji Microsoft Teams z użytkownikami spoza organizacji.'
    }

    function Format-M365TRDomainList($domainSetting) {
        # AllowedDomains/BlockedDomains z Get-CsTenantFederationConfiguration to albo pojedynczy
        # obiekt-znacznik, ktorego ToString() to "AllowAllKnownDomains", albo kolekcja domen.
        if ($null -eq $domainSetting) { return 'Brak' }
        if ("$domainSetting" -eq 'AllowAllKnownDomains') { return 'Wszystkie znane domeny' }
        $items = @($domainSetting | ForEach-Object { if ($_.Domain) { $_.Domain } else { "$_" } }) | Where-Object { $_ -and $_ -ne '' }
        if ($items.Count -eq 0) { return 'Brak' }
        $shown = ($items | Select-Object -First 10) -join ', '
        if ($items.Count -gt 10) { $shown += " (+$($items.Count - 10) więcej)" }
        return $shown
    }

    $rows = foreach ($x in @(
            [PSCustomObject]@{ 'Ustawienie' = 'Federacja z innymi organizacjami Teams/Skype for Business'; 'Wartość' = if ($cfg.AllowFederatedUsers) { 'Dozwolona' } else { 'Zablokowana' } }
            [PSCustomObject]@{ 'Ustawienie' = 'Komunikacja z kontami prywatnymi Teams (konsumenckie)'; 'Wartość' = if ($cfg.AllowTeamsConsumer) { 'Dozwolona' } else { 'Zablokowana' } }
            [PSCustomObject]@{ 'Ustawienie' = 'Przychodzące zaproszenia od kont prywatnych Teams'; 'Wartość' = if ($cfg.AllowTeamsConsumerInbound) { 'Dozwolone' } else { 'Zablokowane' } }
            [PSCustomObject]@{ 'Ustawienie' = 'Komunikacja z kontami Skype (publiczne, konsumenckie)'; 'Wartość' = if ($cfg.AllowPublicUsers) { 'Dozwolona' } else { 'Zablokowana' } }
            [PSCustomObject]@{ 'Ustawienie' = 'Ograniczenie kont prywatnych Teams do zweryfikowanych profili zewnętrznych'; 'Wartość' = if ($cfg.RestrictTeamsConsumerToExternalUserProfiles) { 'Tak' } else { 'Nie' } }
            [PSCustomObject]@{ 'Ustawienie' = 'Dozwolone domeny zewnętrzne'; 'Wartość' = Format-M365TRDomainList $cfg.AllowedDomains }
            [PSCustomObject]@{ 'Ustawienie' = 'Zablokowane domeny zewnętrzne'; 'Wartość' = Format-M365TRDomainList $cfg.BlockedDomains }
        )) { $x }
    $rows = @($rows)

    New-M365TRCollectorResult -Component 'Teams' -Section 'Federacja z innymi organizacjami' `
        -Description 'Ogólnotenantowa konfiguracja federacji Microsoft Teams z użytkownikami spoza organizacji.' `
        -Status 'ok' -Data $rows
}
