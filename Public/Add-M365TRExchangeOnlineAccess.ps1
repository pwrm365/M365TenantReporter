function Add-M365TRExchangeOnlineAccess {
    <#
    .SYNOPSIS
    Extends an existing M365TenantReporter app registration with certificate-based app-only
    access to Exchange Online / Security & Compliance (Purview) PowerShell: generates (or
    reuses) a local self-signed certificate, uploads its public key to the app, grants the
    Exchange.ManageAsApp application permission, and assigns the app's service principal the
    Global Reader directory role (sufficient for read-only Exchange + Compliance access).
    Idempotent - safe to re-run; reuses an existing valid certificate and skips grants/role
    assignments that already exist.
    .PARAMETER Context
    Admin context - needs Application.ReadWrite.All, AppRoleAssignment.ReadWrite.All and
    RoleManagement.ReadWrite.Directory delegated scopes.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)][string]$AppId,
        [Parameter(Mandatory)][string]$ObjectId,
        [Parameter(Mandatory)][string]$ServicePrincipalId,
        [string]$CertSubject = 'CN=M365TenantReporterEXO',
        [int]$CertValidYears = 2
    )

    $failed = New-Object System.Collections.Generic.List[string]

    # 1. Certyfikat - reuse jeśli już istnieje i jest ważny co najmniej 30 dni
    $cert = Get-ChildItem Cert:\CurrentUser\My |
        Where-Object { $_.Subject -eq $CertSubject -and $_.NotAfter -gt (Get-Date).AddDays(30) } |
        Sort-Object NotAfter -Descending | Select-Object -First 1
    if (-not $cert) {
        Write-Host "Generowanie certyfikatu ($CertSubject)..."
        $cert = New-SelfSignedCertificate -Subject $CertSubject -CertStoreLocation 'Cert:\CurrentUser\My' `
            -KeyExportPolicy Exportable -KeySpec Signature -KeyLength 2048 -KeyAlgorithm RSA `
            -HashAlgorithm SHA256 -NotAfter (Get-Date).AddYears($CertValidYears)
    } else {
        Write-Host "Uzywam istniejącego certyfikatu (thumbprint: $($cert.Thumbprint))."
    }

    # 2. Doczepienie klucza publicznego do aplikacji (bez utraty już istniejących kluczy)
    $appDetailResult = Invoke-M365TRGraphRequest -Context $Context -Path "/applications/$ObjectId"
    $existingKeys = if ($appDetailResult.Success -and $appDetailResult.Data.Count -gt 0) { @($appDetailResult.Data[0].keyCredentials) } else { @() }
    $newKeyIdentifier = [Convert]::ToBase64String($cert.GetCertHash())
    $alreadyUploaded = $existingKeys | Where-Object { $_.customKeyIdentifier -eq $newKeyIdentifier }

    if ($alreadyUploaded) {
        Write-Host "Certyfikat już jest doczepiony do aplikacji."
    } else {
        Write-Host "Doczepianie certyfikatu do aplikacji..."
        $newKeyCredential = @{
            type        = 'AsymmetricX509Cert'
            usage       = 'Verify'
            key         = [Convert]::ToBase64String($cert.RawData)
            displayName = 'M365TenantReporter-exo-cert'
        }
        $patchBody = @{ keyCredentials = @($existingKeys) + @($newKeyCredential) }
        $patchResult = Invoke-M365TRGraphWrite -Context $Context -Path "/applications/$ObjectId" -Method PATCH -Body $patchBody
        if (-not $patchResult.Success) { $failed.Add("Certyfikat: $($patchResult.Message)") }
    }

    # 3. Uprawnienie Exchange.ManageAsApp
    $exoResourceAppId = '00000002-0000-0ff1-ce00-000000000000'
    $exoSpResult = Invoke-M365TRGraphRequest -Context $Context -Path "/servicePrincipals?`$filter=appId eq '$exoResourceAppId'"
    if (-not $exoSpResult.Success -or $exoSpResult.Data.Count -eq 0) {
        $failed.Add("Nie znaleziono service principal Office 365 Exchange Online: $($exoSpResult.Message)")
    } else {
        $exoSp = $exoSpResult.Data[0]
        $exoRole = $exoSp.appRoles | Where-Object { $_.value -eq 'Exchange.ManageAsApp' -and $_.allowedMemberTypes -contains 'Application' }
        if (-not $exoRole) {
            $failed.Add('Nie znaleziono uprawnienia Exchange.ManageAsApp w manifescie.')
        } else {
            $existingAssignments = Invoke-M365TRGraphRequest -Context $Context -Path "/servicePrincipals/$ServicePrincipalId/appRoleAssignments"
            $already = $existingAssignments.Success -and ($existingAssignments.Data | Where-Object { $_.appRoleId -eq $exoRole.id })
            if ($already) {
                Write-Host "Uprawnienie Exchange.ManageAsApp już nadane."
            } else {
                $assignResult = Invoke-M365TRGraphWrite -Context $Context -Path "/servicePrincipals/$ServicePrincipalId/appRoleAssignments" -Method POST -Body @{
                    principalId = $ServicePrincipalId
                    resourceId  = $exoSp.id
                    appRoleId   = $exoRole.id
                }
                if (-not $assignResult.Success) { $failed.Add("Exchange.ManageAsApp: $($assignResult.Message)") }
                else { Write-Host "Nadano uprawnienie Exchange.ManageAsApp." }
            }
        }
    }

    # 4. Rola katalogowa Global Reader na service principal aplikacji
    $globalReaderRoleId = 'f2ef992c-3afb-46b9-b7cf-a126ee74c451'
    $existingRoleAssignments = Invoke-M365TRGraphRequest -Context $Context -Path "/roleManagement/directory/roleAssignments?`$filter=principalId eq '$ServicePrincipalId'"
    $alreadyHasRole = $existingRoleAssignments.Success -and ($existingRoleAssignments.Data | Where-Object { $_.roleDefinitionId -eq $globalReaderRoleId })
    if ($alreadyHasRole) {
        Write-Host "Rola Global Reader już przypisana."
    } else {
        $roleResult = Invoke-M365TRGraphWrite -Context $Context -Path '/roleManagement/directory/roleAssignments' -Method POST -Body @{
            principalId      = $ServicePrincipalId
            roleDefinitionId = $globalReaderRoleId
            directoryScopeId = '/'
        }
        if (-not $roleResult.Success) { $failed.Add("Rola Global Reader: $($roleResult.Message)") }
        else { Write-Host "Przypisano role Global Reader." }
    }

    # 5. Domena .onmicrosoft.com (wymagana przez Connect-ExchangeOnline jako -Organization)
    $domainsResult = Invoke-M365TRGraphRequest -Context $Context -Path '/domains'
    $orgDomain = $null
    if ($domainsResult.Success) {
        $orgDomain = ($domainsResult.Data | Where-Object { $_.id -like '*.onmicrosoft.com' -and $_.isInitial } | Select-Object -First 1).id
        if (-not $orgDomain) { $orgDomain = ($domainsResult.Data | Where-Object { $_.id -like '*.onmicrosoft.com' } | Select-Object -First 1).id }
    }
    if (-not $orgDomain) { $failed.Add('Nie udało się ustalic domeny .onmicrosoft.com wymaganej przez Connect-ExchangeOnline.') }

    [PSCustomObject]@{
        Success      = ($failed.Count -eq 0) -and $orgDomain
        Thumbprint   = $cert.Thumbprint
        AppId        = $AppId
        Organization = $orgDomain
        Failed       = @($failed)
    }
}
