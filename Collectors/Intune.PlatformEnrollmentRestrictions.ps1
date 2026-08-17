function Get-Collector_Intune_PlatformEnrollmentRestrictions {
    <#
    .SYNOPSIS
    Które platformy (iOS, Android, Windows, macOS...) w ogole mogą się rejestrować w Intune,
    oraz czy urządzenia prywatne (BYOD) są dopuszczone - to jest rozproszone w zagnieżdżonych
    obiektach wewnątrz deviceEnrollmentPlatformRestrictionsConfiguration i niewidoczne w
    ogólnym podsumowaniu ustawien, więc ma dedykowany kolektor.
    #>
    param([Parameter(Mandatory)]$Context)
    $lang = Get-M365TRLanguage -Context $Context
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/deviceManagement/deviceEnrollmentConfigurations'
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Intune' -Section 'Ograniczenia rejestracji per platforma' -Status $r.Status -Message $r.Message
    }
    $configs = @($r.Data | Where-Object { $_.'@odata.type' -match 'PlatformRestriction' })
    if ($configs.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Intune' -Section 'Ograniczenia rejestracji per platforma' -Status 'empty' `
            -Description 'Które platformy urządzeń mogą się rejestrować w Intune, oraz czy urządzenia prywatne (BYOD) są dopuszczone.'
    }

    if ($lang -eq 'en') {
        $platformLabels = @{
            iosRestriction                = 'iOS/iPadOS'
            androidRestriction            = 'Android (standard enrollment)'
            androidForWorkRestriction     = 'Android Enterprise (work profile)'
            androidDeviceOwnerRestriction = 'Android Enterprise (fully managed)'
            windowsRestriction            = 'Windows'
            windowsMobileRestriction      = 'Windows Mobile'
            windowsHomeSkuRestriction     = 'Windows Home'
            macOSRestriction              = 'macOS'
        }
        $colZasada = 'Rule'; $colPlatforma = 'Platform'; $colRejestracja = 'Enrollment'
        $colByod = 'Personal devices (BYOD)'; $colOsVer = 'Required OS version'
        $blockedLabel = 'Blocked'; $allowedLabel = 'Allowed'; $notApplicableLabel = 'Not applicable'
        $minLabel = 'min.'; $maxLabel = 'max.'; $noneLabel = '-'
    } else {
        $platformLabels = @{
            iosRestriction                = 'iOS/iPadOS'
            androidRestriction            = 'Android (rejestracja standardowa)'
            androidForWorkRestriction     = 'Android Enterprise (profil służbowy)'
            androidDeviceOwnerRestriction = 'Android Enterprise (w pełni zarządzane)'
            windowsRestriction            = 'Windows'
            windowsMobileRestriction      = 'Windows Mobile'
            windowsHomeSkuRestriction     = 'Windows Home'
            macOSRestriction              = 'macOS'
        }
        $colZasada = 'Zasada'; $colPlatforma = 'Platforma'; $colRejestracja = 'Rejestracja'
        $colByod = 'Urządzenia prywatne (BYOD)'; $colOsVer = 'Wymagana wersja systemu'
        $blockedLabel = 'Zablokowana'; $allowedLabel = 'Dozwolona'; $notApplicableLabel = 'Nie dotyczy'
        $minLabel = 'min.'; $maxLabel = 'maks.'; $noneLabel = '-'
    }

    $rows = foreach ($cfg in ($configs | Sort-Object priority)) {
        $restrictionProps = $cfg.PSObject.Properties | Where-Object { $_.Name -like '*Restriction' -and $_.Value -is [PSCustomObject] }
        foreach ($prop in $restrictionProps) {
            $platform = if ($platformLabels.ContainsKey($prop.Name)) { $platformLabels[$prop.Name] } else { ConvertTo-M365TRHumanizedName ($prop.Name -replace 'Restriction$', '') }
            $detail = $prop.Value
            $osRange = New-Object System.Collections.Generic.List[string]
            if ($detail.osMinimumVersion) { $osRange.Add("$minLabel $($detail.osMinimumVersion)") }
            if ($detail.osMaximumVersion) { $osRange.Add("$maxLabel $($detail.osMaximumVersion)") }
            [PSCustomObject]@{
                $colZasada  = $cfg.displayName
                $colPlatforma = $platform
                $colRejestracja = if ($detail.platformBlocked) { $blockedLabel } else { $allowedLabel }
                $colByod    = if ($null -eq $detail.personalDeviceEnrollmentBlocked) { $notApplicableLabel } elseif ($detail.personalDeviceEnrollmentBlocked) { $blockedLabel } else { $allowedLabel }
                $colOsVer   = if ($osRange.Count -gt 0) { $osRange -join ', ' } else { $noneLabel }
            }
        }
    }
    $rows = @($rows)

    New-M365TRCollectorResult -Component 'Intune' -Section 'Ograniczenia rejestracji per platforma' `
        -Description 'Które platformy urządzeń mogą się rejestrować w Intune, oraz czy urządzenia prywatne (BYOD) są dopuszczone - per zasada rejestracji.' `
        -Status 'ok' -Data $rows
}
