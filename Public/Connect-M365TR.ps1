function Connect-M365TR {
    <#
    .SYNOPSIS
    Connects to Microsoft Graph. By default ALWAYS shows a menu of configured tenants (even
    with just one saved) so the operator explicitly picks which tenant/client to work with -
    this app is used across multiple client tenants, so silently reusing "the" saved tenant
    would be actively wrong. Use -TenantId to skip the menu for a specific known tenant,
    -Interactive to sign in fresh (lets you pick any account/tenant in the login window,
    including ones with no app-only setup yet), or -NonInteractive to auto-pick when exactly
    one tenant is configured (for scheduled/unattended runs).
    #>
    [CmdletBinding()]
    param(
        [string]$TenantId,
        [switch]$Interactive,
        [switch]$NonInteractive
    )

    $graphBase = 'https://graph.microsoft.com/'
    $defaultScopes = @(($graphBase.TrimEnd('/')) + '/.default')
    $intuneClientId = '37f82fa9-674e-4cae-9286-4b21eb9a6389'

    function Connect-M365TRInteractiveInternal {
        Write-Host 'Logowanie do Microsoft 365 (może pojawic się okno logowania)...'
        # Nie podajemy -Interactive do Get-MsalToken: MSAL.PS samo przechodzi w tryb
        # interaktywny gdy brak waznego tokenu w cache (sprawdzony dziś wzorzec).
        $token = Get-MsalToken -ClientId $intuneClientId -RedirectUri 'http://localhost' -Scopes $defaultScopes -ForceRefresh
        if (-not $token -or -not $token.AccessToken) { throw 'Logowanie do Microsoft Graph nie powiodło się.' }
        Write-Host "Zalogowano. Token ważny do: $($token.ExpiresOn.LocalDateTime)"
        [PSCustomObject]@{
            ClientId          = $intuneClientId
            Scopes            = $defaultScopes
            GraphBase         = $graphBase
            Token             = $token
            TenantId          = $token.TenantId
            TenantDisplayName = $null
        }
    }

    if ($Interactive) { return Connect-M365TRInteractiveInternal }

    $tenants = @(Get-M365TRStoredTenants)
    $selected = $null

    if ($TenantId) {
        $selected = $tenants | Where-Object { $_.TenantId -eq $TenantId } | Select-Object -First 1
        if (-not $selected) {
            Write-Warning "Nie znaleziono zapisanego tenanta o TenantId '$TenantId' - przechodze na logowanie interaktywne."
            return Connect-M365TRInteractiveInternal
        }
    } elseif ($tenants.Count -eq 0) {
        Write-Host 'Brak zapisanych tenantów (uruchom Setup-AppPermissions.ps1, aby skonfigurować logowanie automatyczne) - logowanie interaktywne.'
        return Connect-M365TRInteractiveInternal
    } elseif ($NonInteractive -and $tenants.Count -eq 1) {
        $selected = $tenants[0]
    } else {
        Write-Host ''
        Write-Host 'Zapisane tenanty:'
        for ($i = 0; $i -lt $tenants.Count; $i++) {
            Write-Host ("  {0}) {1}  ({2})" -f ($i + 1), $tenants[$i].DisplayName, $tenants[$i].Organization)
        }
        $interactiveOptionNumber = $tenants.Count + 1
        Write-Host ("  {0}) Zaloguj się na inne konto/tenant (interaktywnie)" -f $interactiveOptionNumber)
        $choice = $null
        try { $choice = Read-Host "Wybierz numer [1]" } catch { $choice = $null }
        if ([string]::IsNullOrWhiteSpace($choice)) { $choice = '1' }
        $choiceNum = $choice.Trim() -as [int]
        if (-not $choiceNum -or $choiceNum -lt 1 -or $choiceNum -gt $interactiveOptionNumber) {
            Write-Warning 'Nieprawidlowy wybór - uzywam pierwszego zapisanego tenanta.'
            $choiceNum = 1
        }
        if ($choiceNum -eq $interactiveOptionNumber) { return Connect-M365TRInteractiveInternal }
        $selected = $tenants[$choiceNum - 1]
    }

    Write-Host "Logowanie do tenanta '$($selected.DisplayName)' (app-only, non-interaktywne)..."
    $stored = Get-M365TRStoredAppCredential -TenantId $selected.TenantId
    if (-not $stored) {
        Write-Warning 'Brak poświadczeń aplikacji dla tego tenanta - przechodze na logowanie interaktywne.'
        return Connect-M365TRInteractiveInternal
    }

    try {
        $appToken = Get-MsalToken -ClientId $stored.ClientId -ClientSecret $stored.ClientSecret -TenantId $stored.TenantId -Scopes $defaultScopes -ErrorAction Stop
        Write-Host "Zalogowano (app-only) do '$($selected.DisplayName)'. Token ważny do: $($appToken.ExpiresOn.LocalDateTime)"
        [PSCustomObject]@{
            ClientId          = $stored.ClientId
            Scopes            = $defaultScopes
            GraphBase         = $graphBase
            Token             = $appToken
            TenantId          = $selected.TenantId
            TenantDisplayName = $selected.DisplayName
        }
    } catch {
        Write-Warning "Logowanie app-only nie powiodło się ($($_.Exception.Message)) - przechodze na logowanie interaktywne."
        Connect-M365TRInteractiveInternal
    }
}
