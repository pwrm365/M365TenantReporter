function Get-Collector_SharePoint_TenantSharingSettings {
    <#
    .SYNOPSIS
    Ustawienia udostępniania na poziomie tenanta dla SharePoint i OneDrive (poziom udostępniania
    zewnętrznego, typ linków domyślnych, tworzenie witryn, synchronizacja). Wszystkie zwrocone
    przez Microsoft właściwości są pokazane - znane mają polska etykietę, pozostałe humanizowana nazwę.
    #>
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/admin/sharepoint/settings' -Beta
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'SharePoint' -Section 'Ustawienia udostępniania (SharePoint/OneDrive)' -Status $r.Status -Message $r.Message
    }
    $settings = $r.Data | Select-Object -First 1
    if (-not $settings) {
        return New-M365TRCollectorResult -Component 'SharePoint' -Section 'Ustawienia udostępniania (SharePoint/OneDrive)' -Status 'empty' `
            -Description 'Ustawienia udostępniania na poziomie tenanta dla SharePoint i OneDrive.'
    }

    $labelMap = @{
        sharingCapability                                = 'Poziom udostępniania zewnętrznego'
        sharingDomainRestrictionMode                       = 'Ograniczenie udostępniania do wybranych domen'
        sharingAllowedDomainList                           = 'Domeny dozwolone do udostępniania'
        sharingBlockedDomainList                           = 'Domeny zablokowane do udostępniania'
        resharingEnabled                                   = 'Ponowne udostępnianie przez zaproszonych gości'
        isResharingByExternalUsersEnabled                  = 'Ponowne udostępnianie przez użytkowników zewnętrznych'
        fileAnonymousLinkType                              = 'Domyślny typ linku anonimowego dla plików'
        folderAnonymousLinkType                            = 'Domyślny typ linku anonimowego dla folderów'
        defaultSharingLinkType                             = 'Domyślny typ linku udostępniania'
        defaultLinkPermission                              = 'Domyślne uprawnienia linku udostępniania'
        anyoneLinkTrackUsers                               = 'Śledzenie użytkowników korzystających z linków "Dowolna osoba"'
        isAnyoneLinkEnabled                                = 'Linki "Dowolna osoba" (anonimowe)'
        emailAttestationRequired                           = 'Wymagane ponowne potwierdzenie tożsamości (e-mail) dla gości'
        emailAttestationReAuthDays                         = 'Częstotliwość ponownego potwierdzenia tożsamości gości (dni)'
        externalUserExpirationRequired                     = 'Wygasanie dostępu gości zewnętrznych'
        externalUserExpireInDays                           = 'Dostęp gości wygasa po (dni)'
        isSiteCreationEnabled                               = 'Tworzenie nowych witryn SharePoint'
        isSiteCreationUIEnabled                             = 'Interfejs tworzenia witryn widoczny dla użytkowników'
        siteCreationDefaultManagedPath                      = 'Domyślna ścieżka zarządzana dla nowych witryn'
        siteCreationDefaultStorageLimitInMB                 = 'Domyślny limit magazynu nowej witryny (MB)'
        isUnmanagedSyncAppForTenantRestricted               = 'Synchronizacja z niezarządzanych urządzeń'
        excludedFileExtensionsForSyncApp                    = 'Rozszerzenia plików wykluczone z synchronizacji'
        isLegacyAuthProtocolsEnabled                        = 'Starsze (legacy) protokoły uwierzytelniania'
        isRequireAcceptingUserToMatchInvitedUserEnabled     = 'Wymóg logowania tym samym kontem, które zaproszono'
        deletedUserPersonalSiteRetentionPeriodInDays        = 'Przechowywanie witryny OneDrive po usunięciu użytkownika (dni)'
        personalSiteDefaultStorageLimitInMB                 = 'Domyślny limit magazynu OneDrive (MB)'
        isSharePointMobileNotificationEnabled               = 'Powiadomienia w aplikacji mobilnej SharePoint'
        isSharePointNewsfeedEnabled                         = 'Kanał aktualności SharePoint'
        isCommentingOnSitePagesEnabled                      = 'Komentowanie stron witryny'
        isMacSyncAppEnabled                                 = 'Synchronizacja OneDrive na macOS'
        imageTaggingOption                                  = 'Automatyczne tagowanie obrazów (AI)'
    }
    $valueLabels = @{
        sharingCapability = @{
            disabled                        = 'Wyłączone - brak udostępniania na zewnątrz'
            externalUserSharingOnly         = 'Tylko zaproszeni, zweryfikowani goście'
            externalUserAndGuestSharing     = 'Zaproszeni goście oraz linki anonimowe'
            existingExternalUserSharingOnly = 'Tylko już istniejący zaproszeni goście'
        }
        sharingDomainRestrictionMode = @{
            none          = 'Brak ograniczeń domenowych'
            allowList     = 'Tylko dozwolone domeny'
            blockList     = 'Wszystkie oprócz zablokowanych domen'
        }
        defaultSharingLinkType = @{
            none            = 'Brak (wybór przy każdym udostępnieniu)'
            direct          = 'Bezpośredni dostęp (wskazani ludzie)'
            internal        = 'Osoby w organizacji'
            anonymousAccess = 'Dowolna osoba z linkiem'
        }
        defaultLinkPermission = @{ none = 'Brak (wybór przy każdym udostępnieniu)'; view = 'Tylko odczyt'; edit = 'Edycja' }
        fileAnonymousLinkType   = @{ view = 'Tylko odczyt'; edit = 'Edycja' }
        folderAnonymousLinkType = @{ view = 'Tylko odczyt'; edit = 'Edycja' }
    }

    $rows = @(ConvertTo-M365TRLabeledRows -InputObject $settings -LabelMap $labelMap -ValueLabels $valueLabels)
    if ($rows.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'SharePoint' -Section 'Ustawienia udostępniania (SharePoint/OneDrive)' -Status 'empty' `
            -Description 'Obiekt ustawien istnieje, ale nie zawiera żadnych właściwości.'
    }

    New-M365TRCollectorResult -Component 'SharePoint' -Section 'Ustawienia udostępniania (SharePoint/OneDrive)' `
        -Description 'Ustawienia udostępniania zewnętrznego, linków oraz tworzenia witryn na poziomie całego tenanta (SharePoint/OneDrive admin center > Zasady > Udostępnianie).' `
        -Status 'ok' -Data $rows
}
