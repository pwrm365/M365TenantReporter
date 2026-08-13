function Get-Collector_EntraID_PrivilegedAdminsAndMfa {
    <#
    .SYNOPSIS
    Kto ma przypisana rolę uprzywilejowaną (Global Administrator, Security Administrator itd.)
    oraz czy ma zarejestrowane MFA. Celowo NIE pobiera listy wszystkich użytkowników w tenancie -
    to narzędzie dokumentuje konfigurację administracyjną, a nie robi pełnego audytu kont.
    #>
    param([Parameter(Mandatory)]$Context)

    $rolesResult = Invoke-M365TRGraphRequest -Context $Context -Path '/directoryRoles'
    if (-not $rolesResult.Success) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Administratorzy uprzywilejowani i MFA' -Status $rolesResult.Status -Message $rolesResult.Message
    }

    $privilegedRoleNames = @(
        'Global Administrator', 'Privileged Role Administrator', 'Security Administrator',
        'Exchange Administrator', 'SharePoint Administrator', 'User Administrator',
        'Conditional Access Administrator', 'Application Administrator', 'Cloud Application Administrator',
        'Intune Administrator', 'Helpdesk Administrator', 'Billing Administrator', 'Compliance Administrator'
    )
    $privilegedRoles = @($rolesResult.Data | Where-Object { $_.displayName -in $privilegedRoleNames })
    if ($privilegedRoles.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Administratorzy uprzywilejowani i MFA' -Status 'empty' `
            -Description 'Użytkownicy posiadający uprzywilejowane role katalogowe oraz stan rejestracji MFA.'
    }

    $mfaResult = Invoke-M365TRGraphRequest -Context $Context -Path '/reports/authenticationMethods/userRegistrationDetails'
    $mfaByUserId = @{}
    if ($mfaResult.Success) {
        foreach ($u in $mfaResult.Data) { $mfaByUserId[$u.id] = $u.isMfaRegistered }
    }

    $seen = @{}
    $rows = foreach ($role in $privilegedRoles) {
        $membersResult = Invoke-M365TRGraphRequest -Context $Context -Path "/directoryRoles/$($role.id)/members"
        if (-not $membersResult.Success) { continue }
        foreach ($member in $membersResult.Data) {
            $upn = if ($member.userPrincipalName) { $member.userPrincipalName } else { $member.displayName }
            if (-not $upn) { continue }
            $key = "$upn|$($role.displayName)"
            if ($seen.ContainsKey($key)) { continue }
            $seen[$key] = $true
            $mfaStatus = if ($mfaByUserId.ContainsKey($member.id)) {
                if ($mfaByUserId[$member.id]) { 'Tak' } else { 'Nie' }
            } else { 'Nieznany (brak danych z raportu)' }
            [PSCustomObject]@{
                'Użytkownik'         = $upn
                'Rola'               = $role.displayName
                'MFA zarejestrowane' = $mfaStatus
            }
        }
    }
    $rows = @($rows)

    if ($rows.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Administratorzy uprzywilejowani i MFA' -Status 'empty' `
            -Description 'Użytkownicy posiadający uprzywilejowane role katalogowe oraz stan rejestracji MFA.'
    }
    New-M365TRCollectorResult -Component 'EntraID' -Section 'Administratorzy uprzywilejowani i MFA' `
        -Description 'Użytkownicy posiadający uprzywilejowane role katalogowe (Global Administrator, Security Administrator itd.) oraz stan rejestracji MFA.' `
        -Status 'ok' -Data $rows
}
