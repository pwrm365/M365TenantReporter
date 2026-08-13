function ConvertTo-M365TRFriendlyConfigTypeName {
    <#
    .SYNOPSIS
    Polski, czytelny odpowiednik surowej nazwy typu profilu/konfiguracji Intune (np.
    "deviceEnrollmentLimitConfiguration"). Nieznane typy dostaja humanizowana nazwę zamiast
    surowego identyfikatora API.
    #>
    [CmdletBinding()]
    param([AllowEmptyString()][string]$RawType = '')

    if ([string]::IsNullOrWhiteSpace($RawType)) { return 'Nieznany typ' }

    $typeLabels = @{
        deviceEnrollmentLimitConfiguration                   = 'Limit liczby rejestrowanych urządzeń'
        deviceEnrollmentPlatformRestrictionsConfiguration    = 'Ograniczenia platform przy rejestracji'
        deviceEnrollmentPlatformRestrictionConfiguration     = 'Ograniczenia platform przy rejestracji'
        deviceEnrollmentWindowsHelloForBusinessConfiguration = 'Windows Hello for Business'
        windows10EnrollmentCompletionPageConfiguration       = 'Strona kończąca rejestrację (Windows 10)'
        macOSCustom                                          = 'Niestandardowy profil (macOS)'
        windowsUpdateForBusiness                             = 'Windows Update for Business'
        androidWorkProfileGeneralDevice                      = 'Ogólne ustawienia urządzenia - profil służbowy Android'
        iosGeneralDevice                                     = 'Ogólne ustawienia urządzenia (iOS)'
        iosUpdate                                             = 'Aktualizacje (iOS)'
        macOSGeneralDevice                                    = 'Ogólne ustawienia urządzenia (macOS)'
        windows10Custom                                       = 'Niestandardowy profil (Windows 10/11)'
        windows10General                                      = 'Ogólne ustawienia urządzenia (Windows 10/11)'
    }
    if ($typeLabels.ContainsKey($RawType)) { return $typeLabels[$RawType] }
    $stripped = $RawType -replace 'Configuration$', ''
    return ConvertTo-M365TRHumanizedName $stripped
}
