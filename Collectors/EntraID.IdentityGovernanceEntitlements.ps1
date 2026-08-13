function Get-Collector_EntraID_IdentityGovernanceEntitlements {
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/identityGovernance/entitlementManagement/accessPackages'
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Zarządzanie uprawnieniami (Entitlement Management)' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Zarządzanie uprawnieniami (Entitlement Management)' -Status 'empty' `
            -Description 'Pakiety dostępu (Access Packages) w ramach zarzadzania uprawnieniami (Entitlement Management).'
    }
    $flat = $r.Data | ForEach-Object {
        [PSCustomObject]@{
            'Nazwa'  = $_.displayName
            'Opis'   = $_.description
            'Ukryty' = $_.isHidden
        }
    }
    New-M365TRCollectorResult -Component 'EntraID' -Section 'Zarządzanie uprawnieniami (Entitlement Management)' `
        -Description 'Pakiety dostępu (Access Packages) w ramach zarzadzania uprawnieniami (Entitlement Management).' -Status 'ok' -Data $flat
}
