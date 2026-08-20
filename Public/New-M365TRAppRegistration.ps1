function New-M365TRAppRegistration {
    <#
    .SYNOPSIS
    Creates a dedicated Azure AD app registration with exactly the Microsoft Graph
    APPLICATION permissions M365TenantReporter needs, grants admin consent programmatically,
    and issues a client secret - so future runs can authenticate app-only (non-interactive)
    instead of relying on the signed-in user's own delegated access. Requires the signed-in
    account to be Global Administrator (or Privileged Role Administrator + Application
    Administrator) - the actual consent step will fail cleanly with a clear reason otherwise.
    .PARAMETER Context
    An ADMIN context (from Connect-M365TR -AdminSetup), not the normal collection context -
    it needs Application.ReadWrite.All + AppRoleAssignment.ReadWrite.All delegated scopes,
    which the everyday collection client does not carry.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Context,
        [string]$DisplayName = 'M365TenantReporter'
    )

    $graphResourceAppId = '00000003-0000-0000-c000-000000000000'
    $neededPermissions = @(
        'Printer.Read.All'
        'CloudPC.Read.All'
        'EntitlementManagement.Read.All'
        'RoleManagement.Read.Directory'
        'InformationProtectionPolicy.Read.All'
        'DeviceManagementConfiguration.Read.All'
        'DeviceManagementApps.Read.All'
        'DeviceManagementServiceConfig.Read.All'
        'DeviceManagementManagedDevices.Read.All'
        'DeviceManagementRBAC.Read.All'
        'Directory.Read.All'
        'Policy.Read.All'
        'Organization.Read.All'
        'Domain.Read.All'
        'AgreementAcceptance.Read.All'
        'Agreement.Read.All'
        'SecurityEvents.Read.All'
        'UserAuthenticationMethod.Read.All'
        'Reports.Read.All'
        'AuditLog.Read.All'
        'User.Read.All'
        'SharePointTenantSettings.Read.All'
        'PrintConnector.Read.All'
        'DeviceManagementScripts.Read.All'
        'OnPremDirectorySynchronization.Read.All'
        'AccessReview.Read.All'
        'Sites.Read.All'
    )

    Write-Host "Wyszukiwanie service principal Microsoft Graph..."
    $graphSpResult = Invoke-M365TRGraphRequest -Context $Context -Path "/servicePrincipals?`$filter=appId eq '$graphResourceAppId'"
    if (-not $graphSpResult.Success -or $graphSpResult.Data.Count -eq 0) {
        return [PSCustomObject]@{ Success = $false; Message = "Nie udało się odnalezc service principal Microsoft Graph: $($graphSpResult.Message)" }
    }
    $graphSp = $graphSpResult.Data[0]

    $resolvedRoles = New-Object System.Collections.Generic.List[object]
    $unresolvedPermissions = New-Object System.Collections.Generic.List[string]
    foreach ($permName in $neededPermissions) {
        $role = $graphSp.appRoles | Where-Object { $_.value -eq $permName -and $_.allowedMemberTypes -contains 'Application' }
        if ($role) { $resolvedRoles.Add([PSCustomObject]@{ Name = $permName; Id = $role.id }) }
        else { $unresolvedPermissions.Add($permName) }
    }
    if ($unresolvedPermissions.Count -gt 0) {
        Write-Warning "Nie znaleziono w manifescie Graph: $($unresolvedPermissions -join ', ') - pomijam je."
    }

    # Idempotentne: jeśli aplikacja o tej nazwie już istnieje, dołączamy tylko brakujące
    # uprawnienia zamiast tworzyć duplikat (i nowy sekret nie jest wtedy potrzebny).
    $existingAppResult = Invoke-M365TRGraphRequest -Context $Context -Path "/applications?`$filter=displayName eq '$DisplayName'"
    $isNewApp = -not ($existingAppResult.Success -and $existingAppResult.Data.Count -gt 0)

    if ($isNewApp) {
        Write-Host "Tworzenie rejestracji aplikacji '$DisplayName'..."
        $appBody = @{
            displayName            = $DisplayName
            signInAudience         = 'AzureADMyOrg'
            requiredResourceAccess = @(
                @{
                    resourceAppId  = $graphResourceAppId
                    resourceAccess = @($resolvedRoles | ForEach-Object { @{ id = $_.Id; type = 'Role' } })
                }
            )
        }
        $appResult = Invoke-M365TRGraphWrite -Context $Context -Path '/applications' -Method POST -Body $appBody
        if (-not $appResult.Success) {
            return [PSCustomObject]@{ Success = $false; Message = "Nie udało się utworzyć aplikacji: $($appResult.Message)" }
        }
        $app = $appResult.Data
        Write-Host "Aplikacja utworzona: $($app.appId)"

        Write-Host "Tworzenie service principal dla aplikacji..."
        $spResult = Invoke-M365TRGraphWrite -Context $Context -Path '/servicePrincipals' -Method POST -Body @{ appId = $app.appId }
        if (-not $spResult.Success) {
            return [PSCustomObject]@{ Success = $false; Message = "Aplikacja została utworzona (appId: $($app.appId)), ale utworzenie service principal nie powiodło się: $($spResult.Message)"; ClientId = $app.appId }
        }
        $sp = $spResult.Data
        Start-Sleep -Seconds 8 # propagacja nowego service principal w katalogu
    } else {
        $app = $existingAppResult.Data[0]
        Write-Host "Aplikacja '$DisplayName' już istnieje (appId: $($app.appId)) - dołączam tylko brakujące uprawnienia."
        $spResult = Invoke-M365TRGraphRequest -Context $Context -Path "/servicePrincipals?`$filter=appId eq '$($app.appId)'"
        if (-not $spResult.Success -or $spResult.Data.Count -eq 0) {
            return [PSCustomObject]@{ Success = $false; Message = "Aplikacja istnieje, ale nie znaleziono jej service principal: $($spResult.Message)"; ClientId = $app.appId }
        }
        $sp = $spResult.Data[0]
    }

    Write-Host "Sprawdzanie już nadanych uprawnień..."
    $existingAssignmentsResult = Invoke-M365TRGraphRequest -Context $Context -Path "/servicePrincipals/$($sp.id)/appRoleAssignments"
    $existingRoleIds = if ($existingAssignmentsResult.Success) { @($existingAssignmentsResult.Data.appRoleId) } else { @() }

    Write-Host "Nadawanie zgody administratora (admin consent) dla brakujących uprawnień..."
    $granted = New-Object System.Collections.Generic.List[string]
    $failed = New-Object System.Collections.Generic.List[string]
    foreach ($role in $resolvedRoles) {
        if ($existingRoleIds -contains $role.Id) {
            $granted.Add($role.Name)
            continue
        }
        $assignBody = @{
            principalId = $sp.id
            resourceId  = $graphSp.id
            appRoleId   = $role.Id
        }
        $assignResult = Invoke-M365TRGraphWrite -Context $Context -Path "/servicePrincipals/$($sp.id)/appRoleAssignments" -Method POST -Body $assignBody
        if ($assignResult.Success) {
            $granted.Add($role.Name)
        } else {
            $failed.Add("$($role.Name): $($assignResult.Message)")
        }
    }

    $clientSecret = $null
    if ($isNewApp) {
        Write-Host "Tworzenie sekretu klienta..."
        $secretResult = Invoke-M365TRGraphWrite -Context $Context -Path "/applications/$($app.id)/addPassword" -Method POST -Body @{ passwordCredential = @{ displayName = "$DisplayName-secret" } }
        $clientSecret = if ($secretResult.Success) { $secretResult.Data.secretText } else { $null }
    }

    $orgResult = Invoke-M365TRGraphRequest -Context $Context -Path '/organization'
    $tenantId = $Context.Token.TenantId
    $orgDisplayName = $null
    if ($orgResult.Success -and $orgResult.Data.Count -gt 0) {
        if (-not $tenantId) { $tenantId = $orgResult.Data[0].id }
        $orgDisplayName = $orgResult.Data[0].displayName
    }

    [PSCustomObject]@{
        Success                 = ($isNewApp -and $null -ne $clientSecret) -or (-not $isNewApp -and $failed.Count -eq 0)
        ClientId                = $app.appId
        TenantId                = $tenantId
        OrganizationDisplayName = $orgDisplayName
        ClientSecret            = $clientSecret
        IsNewApp                = $isNewApp
        ObjectId                = $app.id
        ServicePrincipalId      = $sp.id
        GrantedPermissions      = @($granted)
        FailedPermissions       = @($failed)
        Message            = if ($isNewApp -and -not $clientSecret) { "Nie udało się utworzyć sekretu klienta: $($secretResult.Message)" }
                              elseif ($failed.Count -gt 0) { "$(if($isNewApp){'Utworzono aplikacje'}else{'Zaktualizowano aplikacje'}), ale $($failed.Count) uprawnień nie zostało nadanych - sprawdź FailedPermissions." }
                              else { 'OK' }
    }
}
