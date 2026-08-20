function Get-Collector_Exchange_RoleGroups {
    <#
    .SYNOPSIS
    Grupy ról Exchange (RBAC) faktycznie posiadające członków - kto ma podwyższone uprawnienia
    administracyjne w Exchange Online/Purview (np. Organization Management, Recipient
    Management, Security Administrator). Exchange ma dziesiątki wbudowanych grup ról bez
    żadnego przypisanego członka - te celowo pomijamy, żeby pokazać tylko realny stan uprawnień,
    a nie pełny katalog niewykorzystanych ról.
    #>
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-RoleGroup }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Grupy ról administracyjnych (RBAC)' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Grupy ról administracyjnych (RBAC)' -Status 'empty' `
            -Description 'Grupy ról Exchange (RBAC) posiadające co najmniej jednego członka.'
    }

    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($rg in $r.Data) {
        $roleGroupName = $rg.Name
        $membersResult = Invoke-M365TREXOCommand -ScriptBlock { Get-RoleGroupMember -Identity $roleGroupName }
        if (-not $membersResult.Success -or $membersResult.Data.Count -eq 0) { continue }
        $memberNames = @($membersResult.Data | ForEach-Object { $_.Name } | Select-Object -First 15)
        $memberList = $memberNames -join ', '
        if ($membersResult.Data.Count -gt 15) { $memberList += " (+$($membersResult.Data.Count - 15) więcej)" }
        $rows.Add([PSCustomObject]@{
            'Nazwa grupy roli'  = $roleGroupName
            'Opis'              = $rg.Description
            'Liczba członków'   = $membersResult.Data.Count
            'Członkowie'        = $memberList
        })
    }

    if ($rows.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Grupy ról administracyjnych (RBAC)' -Status 'empty' `
            -Description 'Grupy ról Exchange (RBAC) posiadające co najmniej jednego członka.'
    }

    New-M365TRCollectorResult -Component 'Exchange' -Section 'Grupy ról administracyjnych (RBAC)' `
        -Description 'Grupy ról Exchange/Purview (RBAC) posiadające co najmniej jednego członka - kto ma podwyższone uprawnienia administracyjne. Wbudowane grupy ról bez żadnego członka są pominięte.' `
        -Status 'ok' -Data $rows
}
