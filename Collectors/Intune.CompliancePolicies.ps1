function Get-Collector_Intune_CompliancePolicies {
    <#
    .SYNOPSIS
    One detailed record per compliance policy (Podstawowe/Ustawienia/Przypisania), mirroring how
    the Intune portal itself documents a policy - every configured requirement gets its own row
    instead of a single condensed summary sentence, plus resolved group/filter assignments.
    #>
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/deviceManagement/deviceCompliancePolicies'
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Intune' -Section 'Polityki zgodności' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Intune' -Section 'Polityki zgodności' -Status 'empty' `
            -Description 'Polityki zgodności urządzeń (Compliance Policies) wymuszane przez Intune.'
    }

    $records = foreach ($p in $r.Data) {
        $platform = $p.'@odata.type' -replace '#microsoft\.graph\.', '' -replace 'CompliancePolicy$', ''
        $basicRows = @(
            [PSCustomObject]@{ Ustawienie = 'Nazwa'; Wartość = $p.displayName }
            [PSCustomObject]@{ Ustawienie = 'Opis'; Wartość = $p.description }
            [PSCustomObject]@{ Ustawienie = 'Platforma'; Wartość = $platform }
            [PSCustomObject]@{ Ustawienie = 'Utworzono'; Wartość = $p.createdDateTime }
            [PSCustomObject]@{ Ustawienie = 'Zmodyfikowano'; Wartość = $p.lastModifiedDateTime }
        ) | Where-Object { $_.Wartość }

        $settingsRows = @(Get-M365TRSettingsDetailRows -InputObject $p)

        $assignRows = @()
        $ar = Invoke-M365TRGraphRequest -Context $Context -Path "/deviceManagement/deviceCompliancePolicies/$($p.id)/assignments"
        if ($ar.Success) { $assignRows = @(Get-M365TRAssignmentRows -Context $Context -Assignments $ar.Data) }

        New-M365TRDetailRecord -Name $p.displayName -Tables @(
            (New-M365TRDetailTable -Title 'Podstawowe' -Rows $basicRows)
            (New-M365TRDetailTable -Title 'Ustawienia' -Rows $settingsRows)
            (New-M365TRDetailTable -Title 'Przypisania' -Rows $assignRows)
        )
    }

    New-M365TRCollectorResult -Component 'Intune' -Section 'Polityki zgodności' `
        -Description 'Polityki zgodności urządzeń (Compliance Policies) wymuszane przez Intune.' -Status 'ok' -Records -Data $records
}
