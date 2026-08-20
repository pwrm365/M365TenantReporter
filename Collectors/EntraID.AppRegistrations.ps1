function Get-M365TRWellKnownResourceAppName {
    param([string]$ResourceAppId)
    switch ($ResourceAppId) {
        '00000003-0000-0000-c000-000000000000' { 'Microsoft Graph' }
        '00000002-0000-0000-c000-000000000000' { 'Windows Azure Active Directory' }
        '00000003-0000-0ff1-ce00-000000000000' { 'Office 365 SharePoint Online' }
        '00000002-0000-0ff1-ce00-000000000000' { 'Office 365 Exchange Online' }
        '48ac35b8-9aa8-4d74-927d-1f4a14a0b239' { 'Microsoft Teams Services' }
        '797f4846-ba00-4fd7-ba43-dac1f8f63013' { 'Windows Azure Service Management API' }
        default { $ResourceAppId }
    }
}

function Get-M365TRCredentialStatus {
    param([datetime]$Now, $EndDateTime, [ValidateSet('pl', 'en')][string]$Language = 'pl')
    if (-not $EndDateTime) { return $null }
    $end = [datetime]$EndDateTime
    $daysLeft = [Math]::Ceiling(($end - $Now).TotalDays)
    $category = if ($daysLeft -lt 0) { 'expired' } elseif ($daysLeft -le 30) { 'soon' } else { 'ok' }
    $label = if ($Language -eq 'en') {
        switch ($category) {
            'expired' { "Expired $([Math]::Abs($daysLeft)) day(s) ago ($($end.ToString('dd.MM.yyyy')))" }
            'soon'    { "Expires in $daysLeft day(s) ($($end.ToString('dd.MM.yyyy')))" }
            'ok'      { "OK - expires $($end.ToString('dd.MM.yyyy'))" }
        }
    } else {
        switch ($category) {
            'expired' { "Wygasł $([Math]::Abs($daysLeft)) dni temu ($($end.ToString('dd.MM.yyyy')))" }
            'soon'    { "Wygasa za $daysLeft dni ($($end.ToString('dd.MM.yyyy')))" }
            'ok'      { "OK - wygasa $($end.ToString('dd.MM.yyyy'))" }
        }
    }
    [PSCustomObject]@{ Category = $category; DaysLeft = $daysLeft; Label = $label }
}

function Get-Collector_EntraID_AppRegistrations {
    <#
    .SYNOPSIS
    Własne rejestracje aplikacji (App Registrations) tenanta - typ kont, żądane uprawnienia oraz,
    najważniejsze, status wygasania każdego sekretu/certyfikatu. Wygasły sekret potrafi wyłączyć
    integrację z dnia na dzień bez ostrzeżenia - to jeden z najczęstszych, cichych incydentów
    w M365. Pokazuje tylko aplikacje zarejestrowane w TYM tenancie (/applications), nie pełną
    listę service principals (która zawiera setki aplikacji firm trzecich/Microsoftu).
    #>
    param([Parameter(Mandatory)]$Context)
    $lang = Get-M365TRLanguage -Context $Context

    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/applications'
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Rejestracje aplikacji (App Registrations)' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        $emptyDescription = if ($lang -eq 'en') { 'Application registrations owned by this tenant, and the expiry status of each secret/certificate.' } else { 'Rejestracje aplikacji będące własnością tego tenanta oraz status wygasania każdego sekretu/certyfikatu.' }
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Rejestracje aplikacji (App Registrations)' -Status 'empty' -Description $emptyDescription
    }

    $audienceLabels = if ($lang -eq 'en') {
        @{
            AzureADMyOrg                        = 'Single tenant (this organization only)'
            AzureADMultipleOrgs                 = 'Multi-tenant (any organization)'
            AzureADandPersonalMicrosoftAccount  = 'Multi-tenant + personal Microsoft accounts'
            PersonalMicrosoftAccount            = 'Personal Microsoft accounts only'
        }
    } else {
        @{
            AzureADMyOrg                        = 'Jednotenantowa (tylko ta organizacja)'
            AzureADMultipleOrgs                 = 'Wielotenantowa (dowolna organizacja)'
            AzureADandPersonalMicrosoftAccount  = 'Wielotenantowa + konta osobiste Microsoft'
            PersonalMicrosoftAccount            = 'Tylko konta osobiste Microsoft'
        }
    }
    $lbl = if ($lang -eq 'en') {
        @{
            ClientId = 'Application (client) ID'; Created = 'Created'; AccountType = 'Supported account types'
            RedirectUris = 'Redirect URIs'; RequiredAccess = 'Requested API permission'
            Secret = 'Secret'; Certificate = 'Certificate'; NoName = '(unnamed)'; NoCredentials = 'No secrets or certificates configured'
            DelegatedRoles = 'delegated'; AppRoles = 'application'
        }
    } else {
        @{
            ClientId = 'Identyfikator aplikacji (klienta)'; Created = 'Utworzono'; AccountType = 'Obsługiwane typy kont'
            RedirectUris = 'Adresy przekierowania (Redirect URIs)'; RequiredAccess = 'Żądane uprawnienie API'
            Secret = 'Sekret'; Certificate = 'Certyfikat'; NoName = '(bez nazwy)'; NoCredentials = 'Brak skonfigurowanych sekretów lub certyfikatów'
            DelegatedRoles = 'delegowane'; AppRoles = 'aplikacyjne'
        }
    }

    $now = Get-Date

    # Sortowanie po najblizszej dacie wygasniecia jakiegokolwiek sekretu/certyfikatu - aplikacje
    # wymagajace natychmiastowej uwagi trafiaja na gore raportu, a nie w losowym/alfabetycznym miejscu.
    $withEarliestExpiry = $r.Data | ForEach-Object {
        $app = $_
        $allCreds = @(@($app.passwordCredentials) + @($app.keyCredentials) | Where-Object { $_.endDateTime })
        $earliest = if ($allCreds.Count -gt 0) { ($allCreds | ForEach-Object { [datetime]$_.endDateTime } | Sort-Object | Select-Object -First 1) } else { [datetime]::MaxValue }
        [PSCustomObject]@{ App = $app; Earliest = $earliest }
    }
    $sortedApps = $withEarliestExpiry | Sort-Object Earliest | ForEach-Object { $_.App }

    $expiredCount = 0
    $soonCount = 0

    $records = $sortedApps | ForEach-Object {
        $app = $_
        $basicRows = @(
            [PSCustomObject]@{ 'Ustawienie' = $lbl.ClientId; 'Wartość' = "$($app.appId)" }
            [PSCustomObject]@{ 'Ustawienie' = $lbl.Created; 'Wartość' = if ($app.createdDateTime) { ([datetime]$app.createdDateTime).ToString('dd.MM.yyyy') } else { '' } }
            [PSCustomObject]@{ 'Ustawienie' = $lbl.AccountType; 'Wartość' = if ($audienceLabels.ContainsKey("$($app.signInAudience)")) { $audienceLabels["$($app.signInAudience)"] } else { "$($app.signInAudience)" } }
        )

        $settingsRows = New-Object System.Collections.Generic.List[object]
        $redirectUris = @(@($app.web.redirectUris) + @($app.spa.redirectUris) + @($app.publicClient.redirectUris) | Where-Object { $_ })
        if ($redirectUris.Count -gt 0) {
            $shown = @($redirectUris | Select-Object -First 10) -join ', '
            if ($redirectUris.Count -gt 10) { $shown += if ($lang -eq 'en') { " (+$($redirectUris.Count - 10) more)" } else { " (+$($redirectUris.Count - 10) więcej)" } }
            $settingsRows.Add([PSCustomObject]@{ 'Ustawienie' = $lbl.RedirectUris; 'Wartość' = $shown })
        }
        foreach ($rra in @($app.requiredResourceAccess)) {
            $resourceName = Get-M365TRWellKnownResourceAppName -ResourceAppId "$($rra.resourceAppId)"
            $scopeCount = @($rra.resourceAccess | Where-Object { $_.type -eq 'Scope' }).Count
            $roleCount = @($rra.resourceAccess | Where-Object { $_.type -eq 'Role' }).Count
            $parts = New-Object System.Collections.Generic.List[string]
            if ($scopeCount -gt 0) { $parts.Add("$scopeCount $($lbl.DelegatedRoles)") }
            if ($roleCount -gt 0) { $parts.Add("$roleCount $($lbl.AppRoles)") }
            $settingsRows.Add([PSCustomObject]@{ 'Ustawienie' = "$($lbl.RequiredAccess): $resourceName"; 'Wartość' = ($parts -join ', ') })
        }

        $credRows = New-Object System.Collections.Generic.List[object]
        foreach ($pc in @($app.passwordCredentials)) {
            $status = Get-M365TRCredentialStatus -Now $now -EndDateTime $pc.endDateTime -Language $lang
            if ($status) {
                if ($status.Category -eq 'expired') { $expiredCount++ } elseif ($status.Category -eq 'soon') { $soonCount++ }
            }
            $credName = if ($pc.displayName) { "$($pc.displayName)" } elseif ($pc.hint) { "***$($pc.hint)" } else { $lbl.NoName }
            $credRows.Add([PSCustomObject]@{ 'Typ' = $lbl.Secret; 'Nazwa' = $credName; 'Status' = if ($status) { $status.Label } else { '' } })
        }
        foreach ($kc in @($app.keyCredentials)) {
            $status = Get-M365TRCredentialStatus -Now $now -EndDateTime $kc.endDateTime -Language $lang
            if ($status) {
                if ($status.Category -eq 'expired') { $expiredCount++ } elseif ($status.Category -eq 'soon') { $soonCount++ }
            }
            $credName = if ($kc.displayName) { "$($kc.displayName)" } else { $lbl.NoName }
            $credRows.Add([PSCustomObject]@{ 'Typ' = $lbl.Certificate; 'Nazwa' = $credName; 'Status' = if ($status) { $status.Label } else { '' } })
        }
        if ($credRows.Count -eq 0) {
            $credRows.Add([PSCustomObject]@{ 'Typ' = ''; 'Nazwa' = ''; 'Status' = $lbl.NoCredentials })
        }

        $recordName = if ($app.displayName) { "$($app.displayName)" } else { "$($app.appId)" }
        New-M365TRDetailRecord -Name $recordName -Tables @(
            (New-M365TRDetailTable -Title 'Podstawowe' -Rows $basicRows)
            (New-M365TRDetailTable -Title 'Ustawienia' -Rows $settingsRows)
            (New-M365TRDetailTable -Title 'Uwierzytelnianie' -Rows $credRows)
        )
    }

    $alertText = if ($expiredCount -gt 0 -or $soonCount -gt 0) {
        if ($lang -eq 'en') { " $expiredCount already expired, $soonCount expiring within 30 days." } else { " $expiredCount już wygasło, $soonCount wygasa w ciągu 30 dni." }
    } else {
        if ($lang -eq 'en') { ' None expiring within 30 days.' } else { ' Żaden nie wygasa w ciągu 30 dni.' }
    }
    $baseDescription = if ($lang -eq 'en') {
        'Application registrations owned by this tenant, requested API permissions, and the expiry status of every secret/certificate - sorted so the most urgent expiry comes first.'
    } else {
        'Rejestracje aplikacji będące własnością tego tenanta, żądane uprawnienia API oraz status wygasania każdego sekretu/certyfikatu - sortowane tak, aby najpilniejszy termin wygaśnięcia był na górze.'
    }

    New-M365TRCollectorResult -Component 'EntraID' -Section 'Rejestracje aplikacji (App Registrations)' `
        -Description "$baseDescription$alertText" -Status 'ok' -Records -Data $records
}
