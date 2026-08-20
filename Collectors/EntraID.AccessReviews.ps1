function Get-M365TRAccessReviewRecurrenceSummary {
    param($Settings, [ValidateSet('pl', 'en')][string]$Language = 'pl')
    $pattern = $Settings.recurrence.pattern
    $range = $Settings.recurrence.range
    if (-not $pattern -or -not $pattern.type -or $pattern.type -eq 'noRecurrence') {
        return if ($Language -eq 'en') { 'One-time (does not repeat)' } else { 'Jednorazowy (bez powtarzania)' }
    }
    $interval = if ($pattern.interval) { $pattern.interval } else { 1 }
    $unit = if ($Language -eq 'en') {
        switch -Wildcard ($pattern.type) {
            '*Daily*'   { 'day(s)' }
            '*Weekly*'  { 'week(s)' }
            '*Monthly*' { 'month(s)' }
            '*Yearly*'  { 'year(s)' }
            default     { $pattern.type }
        }
    } else {
        switch -Wildcard ($pattern.type) {
            '*Daily*'   { 'dni' }
            '*Weekly*'  { 'tygodni' }
            '*Monthly*' { 'miesięcy' }
            '*Yearly*'  { 'lat' }
            default     { $pattern.type }
        }
    }
    $endText = if ($range.type -eq 'noEnd' -or -not $range.type) {
        if ($Language -eq 'en') { 'no end date' } else { 'bez daty końcowej' }
    } elseif ($range.type -eq 'numbered') {
        if ($Language -eq 'en') { "$($range.numberOfOccurrences) occurrence(s)" } else { "$($range.numberOfOccurrences) wystąpień" }
    } else {
        if ($Language -eq 'en') { "until $($range.endDate)" } else { "do $($range.endDate)" }
    }
    if ($Language -eq 'en') { "Every $interval $unit ($endText)" } else { "Co $interval $unit ($endText)" }
}

function Get-Collector_EntraID_AccessReviews {
    <#
    .SYNOPSIS
    Skonfigurowane kampanie przeglądu dostępu (Access Reviews) - okresowa weryfikacja, czy dany
    użytkownik nadal powinien mieć dostęp do grupy/aplikacji/roli. Brak żadnych zdefiniowanych
    przeglądów jest częstym, normalnym stanem w mniejszych organizacjach (funkcja wymaga licencji
    Entra ID Governance / P2) - pojawi się wtedy jako pusta sekcja, nie błąd.
    #>
    param([Parameter(Mandatory)]$Context)
    $lang = Get-M365TRLanguage -Context $Context

    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/identityGovernance/accessReviews/definitions'
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Przeglądy dostępu (Access Reviews)' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Przeglądy dostępu (Access Reviews)' -Status 'empty' `
            -Description 'Skonfigurowane kampanie okresowego przeglądu dostępu (Access Reviews).'
    }

    $decisionLabels = if ($lang -eq 'en') {
        @{ Approve = 'Approve access'; Deny = 'Deny access'; Recommendation = "Follow the system's recommendation" }
    } else {
        @{ Approve = 'Zatwierdź dostęp'; Deny = 'Odrzuć dostęp'; Recommendation = 'Zgodnie z rekomendacją systemu' }
    }

    $records = $r.Data | ForEach-Object {
        $def = $_
        $basicRows = New-Object System.Collections.Generic.List[object]
        if ($lang -eq 'en') {
            $basicRows.Add([PSCustomObject]@{ 'Ustawienie' = 'Description'; 'Wartość' = "$($def.descriptionForAdmins)" })
            $basicRows.Add([PSCustomObject]@{ 'Ustawienie' = 'Status'; 'Wartość' = "$($def.status)" })
            $basicRows.Add([PSCustomObject]@{ 'Ustawienie' = 'Scope (technical query)'; 'Wartość' = "$($def.scope.query)" })
            $reviewerQueries = @($def.reviewers | ForEach-Object { $_.query }) -join ', '
            $basicRows.Add([PSCustomObject]@{ 'Ustawienie' = 'Reviewers'; 'Wartość' = if ($reviewerQueries) { $reviewerQueries } else { 'Self-review (each user reviews their own access)' } })
        } else {
            $basicRows.Add([PSCustomObject]@{ 'Ustawienie' = 'Opis'; 'Wartość' = "$($def.descriptionForAdmins)" })
            $basicRows.Add([PSCustomObject]@{ 'Ustawienie' = 'Status'; 'Wartość' = "$($def.status)" })
            $basicRows.Add([PSCustomObject]@{ 'Ustawienie' = 'Zakres (zapytanie techniczne)'; 'Wartość' = "$($def.scope.query)" })
            $reviewerQueries = @($def.reviewers | ForEach-Object { $_.query }) -join ', '
            $basicRows.Add([PSCustomObject]@{ 'Ustawienie' = 'Recenzenci'; 'Wartość' = if ($reviewerQueries) { $reviewerQueries } else { 'Samoprzegląd (każdy użytkownik przegląda własny dostęp)' } })
        }

        $settingsRows = New-Object System.Collections.Generic.List[object]
        $recurrenceLabel = if ($lang -eq 'en') { 'Recurrence' } else { 'Cykliczność' }
        $settingsRows.Add([PSCustomObject]@{ 'Ustawienie' = $recurrenceLabel; 'Wartość' = (Get-M365TRAccessReviewRecurrenceSummary -Settings $def.settings -Language $lang) })
        if ($null -ne $def.settings.instanceDurationInDays) {
            $settingsRows.Add([PSCustomObject]@{ 'Ustawienie' = if ($lang -eq 'en') { 'Instance duration (days)' } else { 'Czas trwania cyklu (dni)' }; 'Wartość' = "$($def.settings.instanceDurationInDays)" })
        }
        if ($null -ne $def.settings.autoApplyDecisionsEnabled) {
            $settingsRows.Add([PSCustomObject]@{ 'Ustawienie' = if ($lang -eq 'en') { 'Automatically apply decisions' } else { 'Automatyczne stosowanie decyzji' }; 'Wartość' = if ($def.settings.autoApplyDecisionsEnabled) { 'Tak' } else { 'Nie' } })
        }
        if ($def.settings.defaultDecision) {
            $decision = if ($decisionLabels.ContainsKey("$($def.settings.defaultDecision)")) { $decisionLabels["$($def.settings.defaultDecision)"] } else { "$($def.settings.defaultDecision)" }
            $settingsRows.Add([PSCustomObject]@{ 'Ustawienie' = if ($lang -eq 'en') { 'Default decision if no response' } else { 'Domyślna decyzja przy braku odpowiedzi' }; 'Wartość' = $decision })
        }
        if ($null -ne $def.settings.justificationRequiredOnApproval) {
            $settingsRows.Add([PSCustomObject]@{ 'Ustawienie' = if ($lang -eq 'en') { 'Justification required on approval' } else { 'Uzasadnienie wymagane przy zatwierdzeniu' }; 'Wartość' = if ($def.settings.justificationRequiredOnApproval) { 'Tak' } else { 'Nie' } })
        }
        if ($null -ne $def.settings.recommendationsEnabled) {
            $settingsRows.Add([PSCustomObject]@{ 'Ustawienie' = if ($lang -eq 'en') { 'System recommendations enabled' } else { 'Rekomendacje systemowe włączone' }; 'Wartość' = if ($def.settings.recommendationsEnabled) { 'Tak' } else { 'Nie' } })
        }
        if ($null -ne $def.settings.mailNotificationsEnabled) {
            $settingsRows.Add([PSCustomObject]@{ 'Ustawienie' = if ($lang -eq 'en') { 'Email notifications enabled' } else { 'Powiadomienia e-mail włączone' }; 'Wartość' = if ($def.settings.mailNotificationsEnabled) { 'Tak' } else { 'Nie' } })
        }

        $recordName = if ($def.displayName) { $def.displayName } else { $def.id }
        New-M365TRDetailRecord -Name $recordName -Tables @(
            (New-M365TRDetailTable -Title 'Podstawowe' -Rows $basicRows)
            (New-M365TRDetailTable -Title 'Ustawienia' -Rows @($settingsRows))
        )
    }

    New-M365TRCollectorResult -Component 'EntraID' -Section 'Przeglądy dostępu (Access Reviews)' `
        -Description 'Skonfigurowane kampanie okresowego przeglądu dostępu (Access Reviews) - kto podlega przeglądowi, jak często i kto go przeprowadza.' `
        -Status 'ok' -Records -Data $records
}
