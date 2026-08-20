function Get-Collector_Intune_RoleDefinitions {
    <#
    .SYNOPSIS
    Definicje ról RBAC w Intune wraz z pełną listą dozwolonych akcji i przypisaniami (kto ma tę
    rolę) - poprzednio widoczna była tylko nazwa/opis roli, bez informacji co faktycznie
    umożliwia i komu przypisano. Role z uprawnieniami do "CloudPC" (Windows 365) są rozpoznawalne
    po prefiksie akcji w tabeli Uprawnienia, bez potrzeby osobnego kolektora.
    #>
    param([Parameter(Mandatory)]$Context)
    $lang = Get-M365TRLanguage -Context $Context
    $moreLabel = if ($lang -eq 'en') { 'more' } else { 'więcej' }
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/deviceManagement/roleDefinitions'
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Intune' -Section 'Role RBAC w Intune' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Intune' -Section 'Role RBAC w Intune' -Status 'empty' `
            -Description 'Definicje rol RBAC uzywanych do kontroli dostępu w Intune.'
    }

    $records = foreach ($role in $r.Data) {
        $basicRows = @(
            [PSCustomObject]@{ Ustawienie = 'Opis'; Wartość = $role.description }
            [PSCustomObject]@{ Ustawienie = 'Wbudowana'; Wartość = if ($role.isBuiltIn) { 'Tak' } else { 'Nie' } }
        ) | Where-Object { $_.Wartość }

        $permRows = New-Object System.Collections.Generic.List[object]
        foreach ($perm in @($role.rolePermissions)) {
            $allowed = @($perm.resourceActions | ForEach-Object { @($_.allowedResourceActions) }) | Where-Object { $_ }
            if ($allowed.Count -eq 0) { continue }
            $shown = ($allowed | Select-Object -First 25) -join ', '
            if ($allowed.Count -gt 25) { $shown += " (+$($allowed.Count - 25) $moreLabel)" }
            $permRows.Add([PSCustomObject]@{ Ustawienie = 'Dozwolone akcje'; Wartość = $shown })
        }
        if ($permRows.Count -eq 0) {
            $noActionsLabel = if ($lang -eq 'en') { '(no actions defined)' } else { '(brak zdefiniowanych akcji)' }
            $permRows.Add([PSCustomObject]@{ Ustawienie = 'Dozwolone akcje'; Wartość = $noActionsLabel })
        }

        $assignRows = New-Object System.Collections.Generic.List[object]
        $roleAssignResult = Invoke-M365TRGraphRequest -Context $Context -Path "/deviceManagement/roleDefinitions/$($role.id)/roleAssignments"
        if ($roleAssignResult.Success -and $roleAssignResult.Data.Count -gt 0) {
            foreach ($a in $roleAssignResult.Data) {
                $memberCount = @($a.members).Count
                $memberIds = (@($a.members) | Select-Object -First 5) -join ', '
                if ($memberCount -gt 5) { $memberIds += " (+$($memberCount - 5) $moreLabel)" }
                $assignRows.Add([PSCustomObject]@{
                    'Przypisanie'   = $a.displayName
                    'Liczba członków' = $memberCount
                    'Członkowie (ID)' = $memberIds
                })
            }
        }
        if ($assignRows.Count -eq 0) {
            $noAssignmentsLabel = if ($lang -eq 'en') { '(no assignments)' } else { '(brak przypisań)' }
            $assignRows.Add([PSCustomObject]@{ 'Przypisanie' = ''; 'Liczba członków' = 0; 'Członkowie (ID)' = $noAssignmentsLabel })
        }

        New-M365TRDetailRecord -Name $role.displayName -Tables @(
            (New-M365TRDetailTable -Title 'Podstawowe' -Rows $basicRows)
            (New-M365TRDetailTable -Title 'Uprawnienia' -Rows $permRows)
            (New-M365TRDetailTable -Title 'Przypisania' -Rows $assignRows)
        )
    }

    New-M365TRCollectorResult -Component 'Intune' -Section 'Role RBAC w Intune' `
        -Description 'Definicje rol RBAC uzywanych do kontroli dostępu w Intune - pełna lista dozwolonych akcji oraz przypisania (kto ma daną rolę).' -Status 'ok' -Records -Data $records
}
