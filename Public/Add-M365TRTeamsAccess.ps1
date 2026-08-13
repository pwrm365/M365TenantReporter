function Add-M365TRTeamsAccess {
    <#
    .SYNOPSIS
    Extends an existing M365TenantReporter app registration with certificate-based app-only
    access to Microsoft Teams PowerShell (*-Cs cmdlets): assigns the app's service principal
    the Teams Administrator directory role. Reuses the same certificate already uploaded for
    Exchange Online (Teams PowerShell app-only auth just needs a cert + a Teams-capable Entra
    role - per Microsoft's own docs, *-Cs cmdlets need NO extra API permission, and configuring
    the "Skype and Teams Tenant Admin API" permission can actually cause failures, so we
    deliberately do not touch API permissions here). Idempotent - safe to re-run.
    .PARAMETER Context
    Admin context - needs RoleManagement.ReadWrite.Directory delegated scope.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)][string]$ServicePrincipalId
    )

    $failed = New-Object System.Collections.Generic.List[string]

    $teamsAdminRoleId = '69091246-20e8-4a56-aa4d-066075b2a7a8'
    $existingRoleAssignments = Invoke-M365TRGraphRequest -Context $Context -Path "/roleManagement/directory/roleAssignments?`$filter=principalId eq '$ServicePrincipalId'"
    $alreadyHasRole = $existingRoleAssignments.Success -and ($existingRoleAssignments.Data | Where-Object { $_.roleDefinitionId -eq $teamsAdminRoleId })
    if ($alreadyHasRole) {
        Write-Host 'Rola Teams Administrator już przypisana.'
    } else {
        $roleResult = Invoke-M365TRGraphWrite -Context $Context -Path '/roleManagement/directory/roleAssignments' -Method POST -Body @{
            principalId      = $ServicePrincipalId
            roleDefinitionId = $teamsAdminRoleId
            directoryScopeId = '/'
        }
        if (-not $roleResult.Success) { $failed.Add("Rola Teams Administrator: $($roleResult.Message)") }
        else { Write-Host 'Przypisano rolę Teams Administrator.' }
    }

    [PSCustomObject]@{
        Success = ($failed.Count -eq 0)
        Failed  = @($failed)
    }
}
