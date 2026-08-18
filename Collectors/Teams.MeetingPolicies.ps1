function Get-M365TRTeamsMeetingPolicyLabelMap {
    param([ValidateSet('pl', 'en')][string]$Language = 'pl')
    if ($Language -eq 'en') {
        return @{
            AutoAdmittedUsers                       = 'Automatic meeting admission (lobby bypass)'
            AllowPSTNUsersToBypassLobby             = 'Phone (PSTN) callers bypass the lobby'
            AllowOrganizersToOverrideLobbySettings   = 'Organizer can override lobby settings'
            DesignatedPresenterRoleMode              = 'Who can be a presenter'
            AllowExternalParticipantGiveRequestControl = 'External participants can take control of sharing'
            AllowParticipantGiveRequestControl       = 'Participants can request/give control'
            AllowCloudRecording                      = 'Cloud recording allowed'
            AllowLocalRecording                       = 'Local recording allowed'
            AllowRecordingStorageOutsideRegion       = 'Recording storage outside region allowed'
            AutoRecording                             = 'Automatic recording'
            AllowTranscription                        = 'Live transcription allowed'
            LiveCaptionsEnabledType                   = 'Live captions'
            LiveInterpretationEnabledType             = 'Live interpretation'
            AllowMeetNow                              = '"Meet now" meetings allowed'
            AllowMeetingRegistration                  = 'Meeting registration allowed'
            WhoCanRegister                            = 'Who can register'
            AllowPrivateMeetingScheduling             = 'Private meeting scheduling allowed'
            AllowChannelMeetingScheduling             = 'Channel meeting scheduling allowed'
            AllowScheduleAnnouncementFeatures          = 'Announcement (Town Hall) scheduling allowed'
            MeetingChatEnabledType                    = 'Meeting chat'
            AllowAnonymousUsersToJoinMeeting         = 'Anonymous users can join'
            AllowAnonymousUsersToStartMeeting        = 'Anonymous users can start meetings'
            AllowUserToJoinExternalMeeting            = 'Users can join external meetings'
            AllowIPAudio                              = 'IP audio allowed'
            AllowIPVideo                              = 'IP video allowed'
            MediaBitRateKb                            = 'Media bit rate (Kb)'
            ScreenSharingMode                          = 'Screen sharing mode'
            AllowSharedNotes                          = 'Shared notes (whiteboard notes) allowed'
            AllowWhiteboard                           = 'Whiteboard allowed'
            AllowBreakoutRooms                        = 'Breakout rooms allowed'
            AllowImmersiveView                        = 'Immersive view allowed'
            AllowPowerPointSharing                    = 'PowerPoint Live sharing allowed'
            AllowMeetingReactions                     = 'Meeting reactions allowed'
            AllowNDIStreaming                         = 'NDI streaming allowed'
            AllowEngagementReport                      = 'Attendance/engagement report allowed'
            AllowTrackingInReport                     = 'Attendee tracking in report allowed'
            AllowWatermarkForCameraVideo              = 'Watermark on camera video'
            AllowWatermarkForScreenSharing            = 'Watermark on screen sharing'
            VideoFiltersMode                           = 'Video filters (background effects) mode'
            AllowPollsAndQuizzes                      = 'Polls and quizzes allowed'
            AllowAvatarsInGroupCallModality            = 'Avatars in meetings allowed'
            RoomAttributeUserOverride                  = 'Users can override room attributes'
            AllowNetworkConfigurationSettingsLookup   = 'Network configuration lookup allowed'
            Description                               = 'Admin description'
        }
    }
    return @{
        AutoAdmittedUsers                       = 'Automatyczne dopuszczanie do spotkania (poczekalnia)'
        AllowPSTNUsersToBypassLobby             = 'Rozmówcy telefoniczni (PSTN) pomijają poczekalnię'
        AllowOrganizersToOverrideLobbySettings   = 'Organizator może nadpisać ustawienia poczekalni'
        DesignatedPresenterRoleMode              = 'Kto może być prezenterem'
        AllowExternalParticipantGiveRequestControl = 'Uczestnicy zewnętrzni mogą przejąć kontrolę nad udostępnianiem'
        AllowParticipantGiveRequestControl       = 'Uczestnicy mogą prosić/przekazywać kontrolę'
        AllowCloudRecording                      = 'Nagrywanie w chmurze dozwolone'
        AllowLocalRecording                       = 'Nagrywanie lokalne dozwolone'
        AllowRecordingStorageOutsideRegion       = 'Przechowywanie nagrań poza regionem dozwolone'
        AutoRecording                             = 'Automatyczne nagrywanie'
        AllowTranscription                        = 'Transkrypcja na żywo dozwolona'
        LiveCaptionsEnabledType                   = 'Napisy na żywo'
        LiveInterpretationEnabledType             = 'Tłumaczenie na żywo'
        AllowMeetNow                              = 'Spotkania "od razu" dozwolone'
        AllowMeetingRegistration                  = 'Rejestracja na spotkanie dozwolona'
        WhoCanRegister                            = 'Kto może się rejestrować'
        AllowPrivateMeetingScheduling             = 'Planowanie spotkań prywatnych dozwolone'
        AllowChannelMeetingScheduling             = 'Planowanie spotkań w kanale dozwolone'
        AllowScheduleAnnouncementFeatures          = 'Planowanie transmisji (Town Hall) dozwolone'
        MeetingChatEnabledType                    = 'Czat na spotkaniu'
        AllowAnonymousUsersToJoinMeeting         = 'Anonimowi użytkownicy mogą dołączać'
        AllowAnonymousUsersToStartMeeting        = 'Anonimowi użytkownicy mogą rozpoczynać spotkania'
        AllowUserToJoinExternalMeeting            = 'Użytkownicy mogą dołączać do spotkań zewnętrznych'
        AllowIPAudio                              = 'Audio IP dozwolone'
        AllowIPVideo                              = 'Wideo IP dozwolone'
        MediaBitRateKb                            = 'Przepływność mediów (Kb)'
        ScreenSharingMode                          = 'Tryb udostępniania ekranu'
        AllowSharedNotes                          = 'Współdzielone notatki dozwolone'
        AllowWhiteboard                           = 'Tablica (whiteboard) dozwolona'
        AllowBreakoutRooms                        = 'Pokoje robocze (breakout rooms) dozwolone'
        AllowImmersiveView                        = 'Widok immersyjny dozwolony'
        AllowPowerPointSharing                    = 'Udostępnianie PowerPoint Live dozwolone'
        AllowMeetingReactions                     = 'Reakcje na spotkaniu dozwolone'
        AllowNDIStreaming                         = 'Strumieniowanie NDI dozwolone'
        AllowEngagementReport                      = 'Raport frekwencji/zaangażowania dozwolony'
        AllowTrackingInReport                     = 'Śledzenie uczestników w raporcie dozwolone'
        AllowWatermarkForCameraVideo              = 'Znak wodny na obrazie z kamery'
        AllowWatermarkForScreenSharing            = 'Znak wodny na udostępnianym ekranie'
        VideoFiltersMode                           = 'Tryb filtrów wideo (tło)'
        AllowPollsAndQuizzes                      = 'Ankiety i quizy dozwolone'
        AllowAvatarsInGroupCallModality            = 'Awatary na spotkaniach dozwolone'
        RoomAttributeUserOverride                  = 'Użytkownicy mogą nadpisać atrybuty sali'
        AllowNetworkConfigurationSettingsLookup   = 'Wyszukiwanie konfiguracji sieciowej dozwolone'
        Description                               = 'Opis administratora'
    }
}

function Get-Collector_Teams_MeetingPolicies {
    <#
    .SYNOPSIS
    Zasady spotkań Microsoft Teams - pełny zrzut ustawień każdej zasady (poczekalnia, nagrywanie,
    transkrypcja, czat, prezenterzy, udostępnianie i dziesiątki innych przełączników).
    #>
    param([Parameter(Mandatory)]$Context)
    $lang = Get-M365TRLanguage -Context $Context
    $description = if ($lang -eq 'en') {
        'Microsoft Teams meeting policies (recording, transcription, lobby, chat, presenters) - full settings for each policy.'
    } else {
        'Zasady spotkań Microsoft Teams (nagrywanie, transkrypcja, poczekalnia, czat, prezenterzy) - pełny zrzut ustawień każdej zasady.'
    }
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-CsTeamsMeetingPolicy }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Teams' -Section 'Zasady spotkań' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Teams' -Section 'Zasady spotkań' -Status 'empty' -Description $description
    }

    $labelMap = Get-M365TRTeamsMeetingPolicyLabelMap -Language $lang
    $excludeProps = @('Identity', 'Key', 'RunspaceId', 'PSComputerName', 'PSShowComputerName', 'Element', 'CimClass', 'CimInstanceProperties', 'CimSystemProperties')

    $records = $r.Data | ForEach-Object {
        $settingsRows = @(ConvertTo-M365TRLabeledRows -InputObject $_ -LabelMap $labelMap -ExcludeProperties $excludeProps -Language $lang)
        New-M365TRDetailRecord -Name $_.Identity -Tables @(
            (New-M365TRDetailTable -Title 'Ustawienia' -Rows $settingsRows)
        )
    }
    New-M365TRCollectorResult -Component 'Teams' -Section 'Zasady spotkań' `
        -Description $description -Status 'ok' -Records -Data $records
}
