function Get-Collector_Intune_DeviceConfigurations {
    <#
    .SYNOPSIS
    One detailed record per device configuration profile (Podstawowe/Ustawienia/Przypisania) -
    every configured setting listed individually instead of a capped one-line summary, plus
    resolved group/filter assignments.
    #>
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/deviceManagement/deviceConfigurations'
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Intune' -Section 'Profile konfiguracyjne urządzeń' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Intune' -Section 'Profile konfiguracyjne urządzeń' -Status 'empty' `
            -Description 'Profile konfiguracyjne urządzeń (Device Configuration Profiles) zarzadzane przez Intune.'
    }

    $records = foreach ($p in $r.Data) {
        $typeRaw = $p.'@odata.type' -replace '#microsoft\.graph\.', ''
        $basicRows = @(
            [PSCustomObject]@{ Ustawienie = 'Nazwa'; Wartość = $p.displayName }
            [PSCustomObject]@{ Ustawienie = 'Opis'; Wartość = $p.description }
            [PSCustomObject]@{ Ustawienie = 'Typ'; Wartość = (ConvertTo-M365TRFriendlyConfigTypeName $typeRaw) }
            [PSCustomObject]@{ Ustawienie = 'Utworzono'; Wartość = $p.createdDateTime }
            [PSCustomObject]@{ Ustawienie = 'Zmodyfikowano'; Wartość = $p.lastModifiedDateTime }
        ) | Where-Object { $_.Wartość }

        $settingsRows = @(Get-M365TRSettingsDetailRows -InputObject $p)

        $assignRows = @()
        $ar = Invoke-M365TRGraphRequest -Context $Context -Path "/deviceManagement/deviceConfigurations/$($p.id)/assignments"
        if ($ar.Success) { $assignRows = @(Get-M365TRAssignmentRows -Context $Context -Assignments $ar.Data) }

        New-M365TRDetailRecord -Name $p.displayName -Tables @(
            (New-M365TRDetailTable -Title 'Podstawowe' -Rows $basicRows)
            (New-M365TRDetailTable -Title 'Ustawienia' -Rows $settingsRows)
            (New-M365TRDetailTable -Title 'Przypisania' -Rows $assignRows)
        )
    }

    New-M365TRCollectorResult -Component 'Intune' -Section 'Profile konfiguracyjne urządzeń' `
        -Description 'Profile konfiguracyjne urządzeń (Device Configuration Profiles) zarzadzane przez Intune.' -Status 'ok' -Records -Data $records
}
