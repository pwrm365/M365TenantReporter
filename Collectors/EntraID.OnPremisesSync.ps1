function Get-Collector_EntraID_OnPremisesSync {
    <#
    .SYNOPSIS
    Czy tenant jest zsynchronizowany z lokalnym Active Directory (hybrydowy) czy w pełni
    chmurowy, kiedy byla ostatnia synchronizacja, oraz - dla tenantów hybrydowych - jakie funkcje
    synchronizacji są włączone (m.in. synchronizacja skrótów haseł).
    #>
    param([Parameter(Mandatory)]$Context)
    $orgResult = Invoke-M365TRGraphRequest -Context $Context -Path '/organization'
    if (-not $orgResult.Success) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Synchronizacja z lokalnym Active Directory' -Status $orgResult.Status -Message $orgResult.Message
    }
    $org = $orgResult.Data | Select-Object -First 1
    if (-not $org) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Synchronizacja z lokalnym Active Directory' -Status 'empty' `
            -Description 'Informacja o tym, czy tenant jest zsynchronizowany z lokalnym Active Directory (hybrydowy) czy w pełni chmurowy.'
    }

    if (-not $org.onPremisesSyncEnabled) {
        $rows = @([PSCustomObject]@{ 'Ustawienie' = 'Synchronizacja z lokalnym Active Directory'; 'Wartość' = 'Wyłączona - tenant jest w pełni chmurowy (cloud-only), brak synchronizacji katalogu lokalnego.' })
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Synchronizacja z lokalnym Active Directory' `
            -Description 'Informacja o tym, czy tenant jest zsynchronizowany z lokalnym Active Directory (hybrydowy) czy w pełni chmurowy.' `
            -Status 'ok' -Data $rows
    }

    $lastSync = if ($org.onPremisesLastSyncDateTime) { ([datetime]$org.onPremisesLastSyncDateTime).ToString('dd.MM.yyyy HH:mm') } else { 'nieznana' }

    $syncResult = Invoke-M365TRGraphRequest -Context $Context -Path '/directory/onPremisesSynchronization' -Beta
    $features = if ($syncResult.Success -and $syncResult.Data.Count -gt 0) { $syncResult.Data[0].features } else { $null }

    $rows = foreach ($x in @(
            [PSCustomObject]@{ 'Ustawienie' = 'Synchronizacja z lokalnym Active Directory'; 'Wartość' = 'Włączona - tenant jest hybrydowy.' }
            [PSCustomObject]@{ 'Ustawienie' = 'Ostatnia synchronizacja'; 'Wartość' = $lastSync }
        )) { $x }
    if ($features) {
        $featureRows = foreach ($x in @(
                [PSCustomObject]@{ 'Ustawienie' = 'Synchronizacja skrótów haseł (Password Hash Sync)'; 'Wartość' = if ($features.passwordHashSyncEnabled) { 'Włączona' } else { 'Wyłączona' } }
                [PSCustomObject]@{ 'Ustawienie' = 'Zapis zwrotny użytkowników (User Writeback)'; 'Wartość' = if ($features.userWritebackEnabled) { 'Włączony' } else { 'Wyłączony' } }
                [PSCustomObject]@{ 'Ustawienie' = 'Zapis zwrotny urządzeń (Device Writeback)'; 'Wartość' = if ($features.deviceWritebackEnabled) { 'Włączony' } else { 'Wyłączony' } }
                [PSCustomObject]@{ 'Ustawienie' = 'Zapis zwrotny grup Microsoft 365 (Group Writeback)'; 'Wartość' = if ($features.unifiedGroupWritebackEnabled) { 'Włączony' } else { 'Wyłączony' } }
                [PSCustomObject]@{ 'Ustawienie' = 'Synchronizacja UPN dla użytkowników zarządzanych w chmurze'; 'Wartość' = if ($features.synchronizeUpnForManagedUsersEnabled) { 'Włączona' } else { 'Wyłączona' } }
            )) { $x }
        $rows = @($rows) + @($featureRows)
    }
    $rows = @($rows)

    New-M365TRCollectorResult -Component 'EntraID' -Section 'Synchronizacja z lokalnym Active Directory' `
        -Description 'Informacja o tym, czy tenant jest zsynchronizowany z lokalnym Active Directory (hybrydowy) czy w pełni chmurowy, oraz jakie funkcje synchronizacji są włączone.' `
        -Status 'ok' -Data $rows
}
