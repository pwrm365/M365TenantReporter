function Add-M365TRCompliancePermissions {
    <#
    .SYNOPSIS
    OPTIONAL, extra step (not run by default) - assigns the app's service principal the
    Compliance Administrator directory role, on top of the Global Reader role that
    Add-M365TRExchangeOnlineAccess already grants. Global Reader deliberately does not cover
    every Purview/Security & Compliance PowerShell cmdlet - Microsoft gates some
    higher-sensitivity areas (eDiscovery cases, audit log retention policy management, and
    parts of Insider Risk Management) behind dedicated compliance role groups. This unlocks the
    three report sections that otherwise show as "skipped - insufficient permissions":
    Purview.InsiderRiskPolicies, Purview.ComplianceCases, Purview.AuditLogRetentionPolicies.
    Idempotent - safe to re-run.
    .PARAMETER Context
    Admin context - needs RoleManagement.ReadWrite.Directory delegated scope (the same context
    Setup-AppPermissions.ps1 already establishes for the Global Reader / Teams Administrator
    role grants).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)][string]$ServicePrincipalId
    )

    $failed = New-Object System.Collections.Generic.List[string]

    $complianceAdminRoleId = '17315797-102d-40b4-93e0-432062caca18'
    $existingRoleAssignments = Invoke-M365TRGraphRequest -Context $Context -Path "/roleManagement/directory/roleAssignments?`$filter=principalId eq '$ServicePrincipalId'"
    $alreadyHasRole = $existingRoleAssignments.Success -and ($existingRoleAssignments.Data | Where-Object { $_.roleDefinitionId -eq $complianceAdminRoleId })
    if ($alreadyHasRole) {
        Write-Host 'Rola Compliance Administrator już przypisana.'
    } else {
        $roleResult = Invoke-M365TRGraphWrite -Context $Context -Path '/roleManagement/directory/roleAssignments' -Method POST -Body @{
            principalId      = $ServicePrincipalId
            roleDefinitionId = $complianceAdminRoleId
            directoryScopeId = '/'
        }
        if (-not $roleResult.Success) { $failed.Add("Rola Compliance Administrator: $($roleResult.Message)") }
        else { Write-Host 'Przypisano rolę Compliance Administrator.' }
    }

    [PSCustomObject]@{
        Success = ($failed.Count -eq 0)
        Failed  = @($failed)
    }
}
