function Get-Collector_EntraID_HighRiskAppPermissions {
    <#
    .SYNOPSIS
    Aplikacje (service principals) posiadające uprawnienia aplikacyjne wysokiego ryzyka
    (zapis/pełna kontrola: *.ReadWrite.All, *.FullControl.All, *.ReadWrite.Directory, Mail.Send)
    na Microsoft Graph. Celowo NIE wypisuje wszystkich zarejestrowanych aplikacji w tenancie -
    to lista aplikacji z realnym wpływem na bezpieczeństwo, nie pełny inwentarz.
    #>
    param([Parameter(Mandatory)]$Context)

    $graphResourceAppId = '00000003-0000-0000-c000-000000000000'
    $graphSpResult = Invoke-M365TRGraphRequest -Context $Context -Path "/servicePrincipals?`$filter=appId eq '$graphResourceAppId'"
    if (-not $graphSpResult.Success) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Aplikacje z uprawnieniami wysokiego ryzyka' -Status $graphSpResult.Status -Message $graphSpResult.Message
    }
    $graphSp = $graphSpResult.Data | Select-Object -First 1
    if (-not $graphSp) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Aplikacje z uprawnieniami wysokiego ryzyka' -Status 'empty' `
            -Description 'Aplikacje z uprawnieniami aplikacyjnymi wysokiego ryzyka (zapis/pełna kontrola) na Microsoft Graph.'
    }
    $appRoleNameById = @{}
    foreach ($role in $graphSp.appRoles) { $appRoleNameById[$role.id] = $role.value }

    $assignmentsResult = Invoke-M365TRGraphRequest -Context $Context -Path "/servicePrincipals/$($graphSp.id)/appRoleAssignedTo"
    if (-not $assignmentsResult.Success) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Aplikacje z uprawnieniami wysokiego ryzyka' -Status $assignmentsResult.Status -Message $assignmentsResult.Message
    }
    if ($assignmentsResult.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Aplikacje z uprawnieniami wysokiego ryzyka' -Status 'empty' `
            -Description 'Aplikacje z uprawnieniami aplikacyjnymi wysokiego ryzyka (zapis/pełna kontrola) na Microsoft Graph.'
    }

    $rows = foreach ($a in $assignmentsResult.Data) {
        $permName = $appRoleNameById[$a.appRoleId]
        if (-not $permName) { continue }
        $isHighRisk = ($permName -match '\.(ReadWrite|FullControl)\.All$') -or ($permName -match '\.ReadWrite\.Directory$') -or ($permName -in @('Mail.Send', 'Mail.Send.Shared'))
        if (-not $isHighRisk) { continue }
        $granted = if ($a.createdDateTime) { ([datetime]$a.createdDateTime).ToString('dd.MM.yyyy') } else { 'nieznana' }
        [PSCustomObject]@{
            'Aplikacja'   = $a.principalDisplayName
            'Uprawnienie' = $permName
            'Nadano'      = $granted
        }
    }
    $rows = @($rows | Sort-Object Aplikacja, Uprawnienie)

    if ($rows.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Aplikacje z uprawnieniami wysokiego ryzyka' -Status 'empty' `
            -Description 'Aplikacje z uprawnieniami aplikacyjnymi wysokiego ryzyka (zapis/pełna kontrola) na Microsoft Graph.'
    }
    New-M365TRCollectorResult -Component 'EntraID' -Section 'Aplikacje z uprawnieniami wysokiego ryzyka' `
        -Description 'Aplikacje (service principals) z nadanymi uprawnieniami aplikacyjnymi wysokiego ryzyka (odczyt i zapis/pełna kontrola: *.ReadWrite.All, *.FullControl.All, *.ReadWrite.Directory, Mail.Send) na Microsoft Graph. Nie jest to pełna lista wszystkich aplikacji w tenancie - tylko te z uprawnieniami mogącymi modyfikować dane lub konfigurację.' `
        -Status 'ok' -Data $rows
}
