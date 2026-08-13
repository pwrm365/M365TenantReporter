function Get-Collector_EntraID_CrossTenantAccessPolicy {
    <#
    .SYNOPSIS
    Domyślne (tenant-wide) ustawienia współpracy B2B i Direct Connect z innymi tenantami Entra ID,
    oraz zaufanie wobec MFA/zgodności urządzenia/Hybrid Azure AD Join zglaszanego przez inne tenanty.
    #>
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/policies/crossTenantAccessPolicy'
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Polityka dostępu między tenantami (Cross-Tenant Access)' -Status $r.Status -Message $r.Message
    }
    $pol = $r.Data | Select-Object -First 1
    if (-not $pol) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Polityka dostępu między tenantami (Cross-Tenant Access)' -Status 'empty' `
            -Description 'Domyślne ustawienia dostępu między tenantami (Cross-Tenant Access) dla współpracy B2B.'
    }

    function Format-M365TRAccessType($accessSetting) {
        if (-not $accessSetting -or -not $accessSetting.usersAndGroups -or -not $accessSetting.usersAndGroups.accessType) {
            return 'Nieskonfigurowane (wartość domyślna Microsoft)'
        }
        switch ($accessSetting.usersAndGroups.accessType) {
            'allowed' { 'Dozwolona' }
            'blocked' { 'Zablokowana' }
            default { "$($accessSetting.usersAndGroups.accessType)" }
        }
    }
    function Format-M365TRTrustSetting($value) {
        if ($null -eq $value) { return 'Nieskonfigurowane (wartość domyślna Microsoft)' }
        if ($value) { 'Akceptowane od innych tenantów' } else { 'Nieakceptowane od innych tenantów' }
    }

    $default = $pol.default
    $trust = $default.inboundTrust

    $rows = foreach ($x in @(
            [PSCustomObject]@{ 'Ustawienie' = 'Dozwolone chmury Microsoft'; 'Wartość' = if (@($pol.allowedCloudEndpoints).Count -gt 0) { ($pol.allowedCloudEndpoints -join ', ') } else { 'Wszystkie (brak ograniczeń)' } }
            [PSCustomObject]@{ 'Ustawienie' = 'Współpraca B2B - dostęp przychodzący (goście z innych tenantów u nas)'; 'Wartość' = Format-M365TRAccessType $default.b2bCollaborationInbound }
            [PSCustomObject]@{ 'Ustawienie' = 'Współpraca B2B - dostęp wychodzący (nasi użytkownicy jako goście gdzie indziej)'; 'Wartość' = Format-M365TRAccessType $default.b2bCollaborationOutbound }
            [PSCustomObject]@{ 'Ustawienie' = 'Bezpośrednie połączenie (Direct Connect) - przychodzące'; 'Wartość' = Format-M365TRAccessType $default.b2bDirectConnectInbound }
            [PSCustomObject]@{ 'Ustawienie' = 'Bezpośrednie połączenie (Direct Connect) - wychodzące'; 'Wartość' = Format-M365TRAccessType $default.b2bDirectConnectOutbound }
            [PSCustomObject]@{ 'Ustawienie' = 'Zaufanie do MFA zgłoszonego przez inny tenant'; 'Wartość' = Format-M365TRTrustSetting $trust.isMfaAccepted }
            [PSCustomObject]@{ 'Ustawienie' = 'Zaufanie do zgodności urządzenia (Compliant Device) zgłoszonej przez inny tenant'; 'Wartość' = Format-M365TRTrustSetting $trust.isCompliantDeviceAccepted }
            [PSCustomObject]@{ 'Ustawienie' = 'Zaufanie do przyłączenia Hybrid Azure AD zgłoszonego przez inny tenant'; 'Wartość' = Format-M365TRTrustSetting $trust.isHybridAzureADJoinedDeviceAccepted }
        )) { $x }
    $rows = @($rows)

    New-M365TRCollectorResult -Component 'EntraID' -Section 'Polityka dostępu między tenantami (Cross-Tenant Access)' `
        -Description 'Domyślne ustawienia dostępu między tenantami (Cross-Tenant Access) dla współpracy B2B - dotyczą wszystkich tenantów zewnętrznych, dla których nie skonfigurowano osobnych reguł.' `
        -Status 'ok' -Data $rows
}
