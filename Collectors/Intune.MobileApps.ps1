function Get-M365TRMobileAppExtraRows($App) {
    <#
    .SYNOPSIS
    Fields specific to mobileApps (install/uninstall commands, requirements, detection rules,
    return codes) that Get-M365TRSettingsDetailRows' generic pass skips because they're nested
    objects/arrays, not flat scalars.
    #>
    $rows = New-Object System.Collections.Generic.List[object]

    if ($App.publisher) { $rows.Add([PSCustomObject]@{ Ustawienie = 'Wydawca'; Wartość = $App.publisher }) }
    if ($App.installCommandLine) { $rows.Add([PSCustomObject]@{ Ustawienie = 'Polecenie instalacji'; Wartość = $App.installCommandLine }) }
    if ($App.uninstallCommandLine) { $rows.Add([PSCustomObject]@{ Ustawienie = 'Polecenie odinstalowywania'; Wartość = $App.uninstallCommandLine }) }
    if ($App.applicableArchitectures) { $rows.Add([PSCustomObject]@{ Ustawienie = 'Architektura systemu operacyjnego'; Wartość = $App.applicableArchitectures }) }
    if ($App.minimumFreeDiskSpaceInMB) { $rows.Add([PSCustomObject]@{ Ustawienie = 'Wymagane miejsce na dysku (MB)'; Wartość = $App.minimumFreeDiskSpaceInMB }) }
    if ($App.minimumMemoryInMB) { $rows.Add([PSCustomObject]@{ Ustawienie = 'Wymagana pamięć fizyczna (MB)'; Wartość = $App.minimumMemoryInMB }) }
    if ($App.minimumNumberOfProcessors) { $rows.Add([PSCustomObject]@{ Ustawienie = 'Minimalna liczba procesorów logicznych'; Wartość = $App.minimumNumberOfProcessors }) }
    if ($App.minimumCpuSpeedInMHz) { $rows.Add([PSCustomObject]@{ Ustawienie = 'Minimalna szybkość procesora CPU (MHz)'; Wartość = $App.minimumCpuSpeedInMHz }) }
    if ($App.appStoreUrl) { $rows.Add([PSCustomObject]@{ Ustawienie = 'Adres URL sklepu App Store'; Wartość = $App.appStoreUrl }) }
    if ($App.packageId) { $rows.Add([PSCustomObject]@{ Ustawienie = 'Identyfikator pakietu'; Wartość = $App.packageId }) }
    if ($App.bundleId) { $rows.Add([PSCustomObject]@{ Ustawienie = 'Identyfikator pakietu'; Wartość = $App.bundleId }) }
    if ($App.appUrl) { $rows.Add([PSCustomObject]@{ Ustawienie = 'Adres URL aplikacji'; Wartość = $App.appUrl }) }

    if ($App.minimumSupportedOperatingSystem) {
        $active = $App.minimumSupportedOperatingSystem.PSObject.Properties | Where-Object { $_.Value -eq $true }
        if (@($active).Count -gt 0) {
            $rows.Add([PSCustomObject]@{ Ustawienie = 'Minimalna wersja systemu operacyjnego'; Wartość = (($active.Name) -join ', ') })
        }
    }

    if ($App.returnCodes -and @($App.returnCodes).Count -gt 0) {
        $codes = $App.returnCodes | ForEach-Object { "$($_.returnCode);$($_.type)" }
        $rows.Add([PSCustomObject]@{ Ustawienie = 'Kody powrotne'; Wartość = ($codes -join ' | ') })
    }

    if ($App.rules -and @($App.rules).Count -gt 0) {
        $ruleLines = $App.rules | ForEach-Object {
            $ruleType = if ($_.ruleType) { $_.ruleType } else { 'detection' }
            $kind = $_.'@odata.type' -replace '#microsoft\.graph\.win32LobApp', '' -replace 'Rule$', ''
            $detail = switch -Wildcard ($_.'@odata.type') {
                '*FileSystemRule'  { "$($_.path)\$($_.fileOrFolderName) ($($_.operationType))" }
                '*RegistryRule'    { "$($_.keyPath) ($($_.operationType))" }
                '*ProductCodeRule' { "MSI ProductCode $($_.productCode)" }
                '*PowerShellScriptRule' { 'Skrypt PowerShell' }
                default { '' }
            }
            "[$ruleType/$kind] $detail".Trim()
        }
        $rows.Add([PSCustomObject]@{ Ustawienie = 'Reguły wykrywania/wymagań'; Wartość = ($ruleLines -join ' | ') })
    }

    return $rows
}

function Get-Collector_Intune_MobileApps {
    <#
    .SYNOPSIS
    One detailed record per app (Podstawowe/Ustawienia/Przypisania) - install/uninstall commands,
    requirements, detection rules and resolved group/filter assignments, not just name+publisher.
    #>
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/deviceAppManagement/mobileApps'
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Intune' -Section 'Aplikacje mobilne' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Intune' -Section 'Aplikacje mobilne' -Status 'empty' `
            -Description 'Aplikacje mobilne opublikowane w Intune (Mobile Apps).'
    }

    $records = foreach ($app in $r.Data) {
        $typeRaw = $app.'@odata.type' -replace '#microsoft\.graph\.', ''
        $basicRows = @(
            [PSCustomObject]@{ Ustawienie = 'Nazwa'; Wartość = $app.displayName }
            [PSCustomObject]@{ Ustawienie = 'Opis'; Wartość = $app.description }
            [PSCustomObject]@{ Ustawienie = 'Typ'; Wartość = (ConvertTo-M365TRFriendlyConfigTypeName $typeRaw) }
            [PSCustomObject]@{ Ustawienie = 'Utworzono'; Wartość = $app.createdDateTime }
            [PSCustomObject]@{ Ustawienie = 'Zmodyfikowano'; Wartość = $app.lastModifiedDateTime }
        ) | Where-Object { $_.Wartość }

        $extraRows = @(Get-M365TRMobileAppExtraRows -App $app)
        $genericRows = @(Get-M365TRSettingsDetailRows -InputObject $app -ExcludeProperties @(
            'id', '@odata.type', 'displayName', 'description', 'createdDateTime', 'lastModifiedDateTime',
            'publisher', 'installCommandLine', 'uninstallCommandLine', 'applicableArchitectures',
            'minimumFreeDiskSpaceInMB', 'minimumMemoryInMB', 'minimumNumberOfProcessors', 'minimumCpuSpeedInMHz',
            'appStoreUrl', 'packageId', 'bundleId', 'appUrl'
        ))
        $settingsRows = @($extraRows) + @($genericRows)

        $assignRows = @()
        $ar = Invoke-M365TRGraphRequest -Context $Context -Path "/deviceAppManagement/mobileApps/$($app.id)/assignments"
        if ($ar.Success) { $assignRows = @(Get-M365TRAssignmentRows -Context $Context -Assignments $ar.Data) }

        New-M365TRDetailRecord -Name $app.displayName -Tables @(
            (New-M365TRDetailTable -Title 'Podstawowe' -Rows $basicRows)
            (New-M365TRDetailTable -Title 'Ustawienia' -Rows $settingsRows)
            (New-M365TRDetailTable -Title 'Przypisania' -Rows $assignRows)
        )
    }

    New-M365TRCollectorResult -Component 'Intune' -Section 'Aplikacje mobilne' `
        -Description 'Aplikacje mobilne opublikowane w Intune (Mobile Apps).' -Status 'ok' -Records -Data $records
}
