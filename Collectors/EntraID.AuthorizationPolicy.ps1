function Get-Collector_EntraID_AuthorizationPolicy {
    <#
    .SYNOPSIS
    Ustawienia ogolnotenantowe dotyczące użytkowników i gości: kto może zapraszać gości, jaki
    dostęp mają goście, self-service password reset, oraz domyślne uprawnienia standardowego
    użytkownika (zakładanie aplikacji/grup zabezpieczeń, odczyt innych użytkowników).
    #>
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/policies/authorizationPolicy'
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Ustawienia użytkowników i gości' -Status $r.Status -Message $r.Message
    }
    $pol = $r.Data | Select-Object -First 1
    if (-not $pol) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Ustawienia użytkowników i gości' -Status 'empty' `
            -Description 'Ogolnotenantowe ustawienia dotyczące użytkowników i gości (zapraszanie, dostęp, domyślne uprawnienia).'
    }

    $invitePolicyNames = @{
        none                                = 'Nikt (zapraszanie gości wyłączone)'
        adminsAndGuestInviters              = 'Tylko administratorzy i wyznaczeni zapraszający'
        adminsGuestInvitersAndAllMembers    = 'Administratorzy, wyznaczeni zapraszający i wszyscy członkowie'
        everyone                            = 'Wszyscy użytkownicy (w tym goście)'
    }
    $guestRoleNames = @{
        '10dae51f-b6af-4016-8d66-8c2a99b929b3' = 'Taki sam dostęp jak członkowie (najbardziej permisywne)'
        '2af84b1e-32c8-42b7-82bc-daa82404023b' = 'Ograniczony dostęp do właściwości i członkostw innych obiektów katalogu (domyślne)'
        'a0b1b346-4d3e-4e8b-98f8-753987be4970' = 'Dostęp ograniczony do właściwości i członkostw własnych obiektów (najbardziej restrykcyjne)'
    }
    $perms = $pol.defaultUserRolePermissions

    $rows = foreach ($x in @(
            [PSCustomObject]@{ 'Ustawienie' = 'Kto może zapraszać gości'; 'Wartość' = if ($invitePolicyNames.ContainsKey($pol.allowInvitesFrom)) { $invitePolicyNames[$pol.allowInvitesFrom] } else { "$($pol.allowInvitesFrom)" } }
            [PSCustomObject]@{ 'Ustawienie' = 'Poziom dostępu gości'; 'Wartość' = if ($guestRoleNames.ContainsKey($pol.guestUserRoleId)) { $guestRoleNames[$pol.guestUserRoleId] } else { "Niestandardowa rola ($($pol.guestUserRoleId))" } }
            [PSCustomObject]@{ 'Ustawienie' = 'Self-service reset hasła (SSPR)'; 'Wartość' = if ($pol.allowedToUseSSPR) { 'Włączony' } else { 'Wyłączony' } }
            [PSCustomObject]@{ 'Ustawienie' = 'Zapisywanie się do subskrypcji e-mail (self-service sign-up)'; 'Wartość' = if ($pol.allowedToSignUpEmailBasedSubscriptions) { 'Dozwolone' } else { 'Zablokowane' } }
            [PSCustomObject]@{ 'Ustawienie' = 'Dołączanie do organizacji po weryfikacji e-mail domeny'; 'Wartość' = if ($pol.allowEmailVerifiedUsersToJoinOrganization) { 'Dozwolone' } else { 'Zablokowane' } }
            [PSCustomObject]@{ 'Ustawienie' = 'Dostęp do starszego interfejsu MSOnline PowerShell'; 'Wartość' = if ($pol.blockMsolPowerShell) { 'Zablokowany' } else { 'Dozwolony' } }
        )) { $x }
    if ($perms) {
        $permRows = foreach ($x in @(
                [PSCustomObject]@{ 'Ustawienie' = 'Użytkownicy mogą rejestrować aplikacje (app registrations)'; 'Wartość' = if ($perms.allowedToCreateApps) { 'Tak' } else { 'Nie' } }
                [PSCustomObject]@{ 'Ustawienie' = 'Użytkownicy mogą zakładać grupy zabezpieczeń'; 'Wartość' = if ($perms.allowedToCreateSecurityGroups) { 'Tak' } else { 'Nie' } }
                [PSCustomObject]@{ 'Ustawienie' = 'Użytkownicy mogą odczytywać dane innych użytkowników'; 'Wartość' = if ($perms.allowedToReadOtherUsers) { 'Tak' } else { 'Nie' } }
            )) { $x }
        $rows = @($rows) + @($permRows)
        if ($null -ne $perms.allowedToCreateTenants) {
            $rows = @($rows) + [PSCustomObject]@{ 'Ustawienie' = 'Użytkownicy mogą tworzyć nowe tenanty Entra ID'; 'Wartość' = if ($perms.allowedToCreateTenants) { 'Tak' } else { 'Nie' } }
        }
    }
    $rows = @($rows)

    New-M365TRCollectorResult -Component 'EntraID' -Section 'Ustawienia użytkowników i gości' `
        -Description 'Ogolnotenantowe ustawienia dotyczące użytkowników i gości: zapraszanie, poziom dostępu, self-service oraz domyślne uprawnienia standardowego użytkownika.' `
        -Status 'ok' -Data $rows
}
