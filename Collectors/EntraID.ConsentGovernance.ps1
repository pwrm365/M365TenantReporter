function Get-Collector_EntraID_ConsentGovernance {
    <#
    .SYNOPSIS
    Czy zwykli użytkownicy mogą sami wyrazić zgodę na uprawnienia żądane przez aplikacje
    (app consent), i jeśli administrator musi to zatwierdzać - czy jest do tego skonfigurowany
    przepływ pracy (Admin Consent Workflow) z recenzentami. Jeden z najważniejszych, a najczęściej
    pomijanych ustawień bezpieczeństwa tenanta - szeroki self-service consent to klasyczny wektor
    ataku (złośliwa aplikacja OAuth).
    #>
    param([Parameter(Mandatory)]$Context)
    $lang = Get-M365TRLanguage -Context $Context

    $authPolResult = Invoke-M365TRGraphRequest -Context $Context -Path '/policies/authorizationPolicy'
    if (-not $authPolResult.Success) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Zgoda na aplikacje (App Consent)' -Status $authPolResult.Status -Message $authPolResult.Message
    }
    $authPol = $authPolResult.Data | Select-Object -First 1

    $grantPoliciesResult = Invoke-M365TRGraphRequest -Context $Context -Path '/policies/permissionGrantPolicies'
    $grantPolicyNameById = @{}
    if ($grantPoliciesResult.Success) {
        foreach ($p in $grantPoliciesResult.Data) {
            $policyId = "$($p.id)"
            $grantPolicyNameById[$policyId] = if ($p.displayName) { "$($p.displayName)" } else { $policyId }
        }
    }

    $rows = New-Object System.Collections.Generic.List[object]

    $assignedIds = @($authPol.defaultUserRolePermissions.permissionGrantPoliciesAssigned) | Where-Object { $_ } | ForEach-Object { "$_" }
    $consentValue = if (@($assignedIds).Count -eq 0) {
        if ($lang -eq 'en') { 'No - every consent requires administrator approval' } else { 'Nie - każda zgoda wymaga zatwierdzenia przez administratora' }
    } else {
        $names = @($assignedIds | ForEach-Object { if ($grantPolicyNameById.ContainsKey($_)) { $grantPolicyNameById[$_] } else { $_ } })
        if ($lang -eq 'en') { "Yes - per policy: $($names -join ', ')" } else { "Tak - wg zasady: $($names -join ', ')" }
    }
    $rows.Add([PSCustomObject]@{ 'Ustawienie' = 'Czy zwykli użytkownicy mogą sami wyrazić zgodę na aplikacje'; 'Wartość' = $consentValue })

    $adminConsentResult = Invoke-M365TRGraphRequest -Context $Context -Path '/policies/adminConsentRequestPolicy'
    if ($adminConsentResult.Success -and $adminConsentResult.Data) {
        $acp = $adminConsentResult.Data | Select-Object -First 1
        $rows.Add([PSCustomObject]@{ 'Ustawienie' = 'Przepływ pracy zgody administratora (Admin Consent Workflow)'; 'Wartość' = if ($acp.isEnabled) { 'Włączony' } else { 'Wyłączony' } })
        if ($acp.isEnabled) {
            $rows.Add([PSCustomObject]@{ 'Ustawienie' = 'Powiadamianie recenzentów o nowych żądaniach'; 'Wartość' = if ($acp.notifyReviewers) { 'Tak' } else { 'Nie' } })
            $rows.Add([PSCustomObject]@{ 'Ustawienie' = 'Przypomnienia o oczekujących żądaniach'; 'Wartość' = if ($acp.remindersEnabled) { 'Tak' } else { 'Nie' } })
            $rows.Add([PSCustomObject]@{ 'Ustawienie' = 'Ważność żądania (dni)'; 'Wartość' = "$($acp.requestDurationInDays)" })
            $reviewerCount = @($acp.reviewers).Count
            $rows.Add([PSCustomObject]@{ 'Ustawienie' = 'Liczba wyznaczonych recenzentów'; 'Wartość' = "$reviewerCount" })
        }
    }

    New-M365TRCollectorResult -Component 'EntraID' -Section 'Zgoda na aplikacje (App Consent)' `
        -Description 'Czy zwykli użytkownicy mogą sami wyrazić zgodę na uprawnienia żądane przez aplikacje, oraz konfiguracja przepływu pracy zgody administratora (Admin Consent Workflow) gdy nie mogą.' `
        -Status 'ok' -Data $rows
}
