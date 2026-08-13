function Get-Collector_Teams_MeetingPolicies {
    <#
    .SYNOPSIS
    Zasady spotkań Microsoft Teams (kto może dołączać bez poczekalni, nagrywanie, transkrypcja,
    czat, prezenterzy) - najważniejsze ustawienia z każdej zasady, nie pełny zrzut (Teams ma
    dziesiątki właściwości per zasada).
    #>
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-CsTeamsMeetingPolicy }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Teams' -Section 'Zasady spotkań' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Teams' -Section 'Zasady spotkań' -Status 'empty' `
            -Description 'Zasady spotkań Microsoft Teams (nagrywanie, transkrypcja, poczekalnia, czat, prezenterzy).'
    }

    $autoAdmitNames = @{
        Everyone                        = 'Wszyscy (bez poczekalni)'
        EveryoneInCompany                = 'Wszyscy w organizacji'
        EveryoneInSameAndFederatedCompany = 'Organizacja i tenanty zfederowane'
        OrganizerOnly                    = 'Tylko organizator zatwierdza'
        InvitedUsers                     = 'Tylko zaproszeni użytkownicy'
    }
    $presenterNames = @{
        EveryoneUserOverride = 'Wszyscy (organizator może zmienić)'
        EveryoneInCompany     = 'Wszyscy w organizacji'
        OrganizerOnly         = 'Tylko organizator'
    }

    $flat = $r.Data | ForEach-Object {
        $parts = New-Object System.Collections.Generic.List[string]
        if ($_.AutoAdmittedUsers) {
            $lobby = if ($autoAdmitNames.ContainsKey("$($_.AutoAdmittedUsers)")) { $autoAdmitNames["$($_.AutoAdmittedUsers)"] } else { "$($_.AutoAdmittedUsers)" }
            $parts.Add("automatyczne dopuszczanie do spotkania: $lobby")
        }
        if ($_.AllowPSTNUsersToBypassLobby -eq $true) { $parts.Add('użytkownicy dzwoniący telefonicznie pomijają poczekalnię') }
        if ($null -ne $_.DesignatedPresenterRoleMode) {
            $presenter = if ($presenterNames.ContainsKey("$($_.DesignatedPresenterRoleMode)")) { $presenterNames["$($_.DesignatedPresenterRoleMode)"] } else { "$($_.DesignatedPresenterRoleMode)" }
            $parts.Add("kto może być prezenterem: $presenter")
        }
        if ($_.AllowCloudRecording -eq $true) { $parts.Add('nagrywanie w chmurze dozwolone') }
        if ($_.AllowTranscription -eq $true) { $parts.Add('transkrypcja na żywo dozwolona') }
        if ($_.AllowMeetNow -eq $true) { $parts.Add('spotkania "od razu" dozwolone') }
        if ($_.AllowAnonymousUsersToJoinMeeting -eq $true) { $parts.Add('anonimowi użytkownicy mogą dołączać') }
        if ($_.AllowAnonymousUsersToStartMeeting -eq $true) { $parts.Add('anonimowi użytkownicy mogą rozpoczynać spotkania') }
        if ($_.MeetingChatEnabledType) { $parts.Add("czat na spotkaniu: $($_.MeetingChatEnabledType)") }
        if ($_.AllowExternalParticipantGiveRequestControl -eq $true) { $parts.Add('uczestnicy zewnętrzni mogą przejąć kontrolę nad udostępnianiem') }
        $summary = if ($parts.Count -gt 0) { $parts -join '; ' } else { '(domyślne ustawienia, bez dodatkowych włączonych funkcji)' }

        [PSCustomObject]@{
            'Nazwa'   = $_.Identity
            'Co robi' = $summary
        }
    }
    New-M365TRCollectorResult -Component 'Teams' -Section 'Zasady spotkań' `
        -Description 'Zasady spotkań Microsoft Teams (nagrywanie, transkrypcja, poczekalnia, czat, prezenterzy).' -Status 'ok' -Data $flat
}
