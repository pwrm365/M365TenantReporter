function Add-M365TRSharePointAdminAccess {
    <#
    .SYNOPSIS
    OPTIONAL, extra step (not run by default) - grants the app the legacy SharePoint
    "Sites.FullControl.All" APPLICATION permission, reusing the certificate already uploaded
    for Exchange Online. This is a genuinely broad permission (full control over ALL SharePoint
    site content in the tenant, not just admin settings) - there is no narrower app-only
    permission that still allows reading tenant-admin-level data (Home Site, Hub Sites, tenant
    settings) via SharePoint Online/PnP; Microsoft Graph's own Sites.Read.All does not cover
    these admin-only operations at all. Unlocks SharePoint.PnpHomeSite, SharePoint.PnpHubSites,
    and SharePoint.PnpTenantSettings, which otherwise stay skipped. Idempotent - safe to re-run.
    .PARAMETER Context
    Admin context - needs Application.ReadWrite.All and AppRoleAssignment.ReadWrite.All
    delegated scopes (the same context Setup-AppPermissions.ps1 already establishes).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)][string]$ServicePrincipalId
    )

    $failed = New-Object System.Collections.Generic.List[string]

    $spoResourceAppId = '00000003-0000-0ff1-ce00-000000000000'
    $spoSpResult = Invoke-M365TRGraphRequest -Context $Context -Path "/servicePrincipals?`$filter=appId eq '$spoResourceAppId'"
    if (-not $spoSpResult.Success -or $spoSpResult.Data.Count -eq 0) {
        $failed.Add("Nie znaleziono service principal Office 365 SharePoint Online: $($spoSpResult.Message)")
    } else {
        $spoSp = $spoSpResult.Data[0]
        $spoRole = $spoSp.appRoles | Where-Object { $_.value -eq 'Sites.FullControl.All' -and $_.allowedMemberTypes -contains 'Application' }
        if (-not $spoRole) {
            $failed.Add('Nie znaleziono uprawnienia Sites.FullControl.All w manifescie SharePoint Online.')
        } else {
            $existingAssignments = Invoke-M365TRGraphRequest -Context $Context -Path "/servicePrincipals/$ServicePrincipalId/appRoleAssignments"
            $already = $existingAssignments.Success -and ($existingAssignments.Data | Where-Object { $_.appRoleId -eq $spoRole.id })
            if ($already) {
                Write-Host 'Uprawnienie Sites.FullControl.All już nadane.'
            } else {
                $assignResult = Invoke-M365TRGraphWrite -Context $Context -Path "/servicePrincipals/$ServicePrincipalId/appRoleAssignments" -Method POST -Body @{
                    principalId = $ServicePrincipalId
                    resourceId  = $spoSp.id
                    appRoleId   = $spoRole.id
                }
                if (-not $assignResult.Success) { $failed.Add("Sites.FullControl.All: $($assignResult.Message)") }
                else { Write-Host 'Nadano uprawnienie Sites.FullControl.All.' }
            }
        }
    }

    [PSCustomObject]@{
        Success = ($failed.Count -eq 0)
        Failed  = @($failed)
    }
}
