function Get-Collector_Intune_RoleDefinitions {
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/deviceManagement/roleDefinitions'
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Intune' -Section 'Role RBAC w Intune' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Intune' -Section 'Role RBAC w Intune' -Status 'empty' `
            -Description 'Definicje rol RBAC uzywanych do kontroli dostępu w Intune.'
    }
    $flat = $r.Data | ForEach-Object {
        [PSCustomObject]@{
            'Nazwa'     = $_.displayName
            'Opis'      = $_.description
            'Wbudowana' = $_.isBuiltIn
        }
    }
    New-M365TRCollectorResult -Component 'Intune' -Section 'Role RBAC w Intune' `
        -Description 'Definicje rol RBAC uzywanych do kontroli dostępu w Intune.' -Status 'ok' -Data $flat
}
