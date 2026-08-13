function Get-Collector_EntraID_GroupSettings {
    <#
    .SYNOPSIS
    Ustawienia tworzenia i nazewnictwa grup Microsoft 365 (kto może zakładać grupy, czy goście
    mogą być właścicielami/członkami, wymagany prefiks/sufiks nazwy, zablokowane słowa).
    #>
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/groupSettings'
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Ustawienia grup Microsoft 365' -Status $r.Status -Message $r.Message
    }
    $groupUnified = $r.Data | Where-Object { $_.displayName -eq 'Group.Unified' } | Select-Object -First 1
    if (-not $groupUnified) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Ustawienia grup Microsoft 365' -Status 'empty' `
            -Description 'Brak niestandardowej konfiguracji ustawien grup Microsoft 365 w tym tenancie - obowiązują domyślne wartości Microsoft (m.in. tworzenie grup dostępne dla wszystkich użytkowników, goście nie mogą być właścicielami grup).'
    }

    $labelMap = @{
        EnableGroupCreation           = 'Tworzenie grup Microsoft 365 dostępne dla wszystkich użytkowników'
        GroupCreationAllowedGroupId   = 'Grupa zabezpieczeń uprawniona do tworzenia grup (Id)'
        AllowGuestsToBeGroupOwner     = 'Goście mogą być właścicielami grup'
        AllowGuestsToAccessGroups     = 'Goście mogą uzyskać dostęp do zawartości grup'
        AllowToAddGuests              = 'Możliwość dodawania gości do grup'
        GuestUsageGuidelinesUrl       = 'Link do wytycznych uzytkowania dla gości'
        UsageGuidelinesUrl            = 'Link do wytycznych uzytkowania'
        ClassificationList            = 'Dostępne klasyfikacje grup'
        DefaultClassification         = 'Domyślna klasyfikacja nowej grupy'
        EnableMSStandardBlockedWords  = 'Standardowa lista zablokowanych słów (Microsoft)'
        CustomBlockedWordsList        = 'Niestandardowa lista zablokowanych słów'
        PrefixSuffixNamingRequirement = 'Wymagany wzorzec nazwy (prefiks/sufiks)'
        NamingConvention              = 'Wymagany wzorzec nazwy (prefiks/sufiks)'
    }

    $flatSettings = $groupUnified.values | ForEach-Object -Begin { $o = [ordered]@{} } -Process { $o[$_.name] = $_.value } -End { [PSCustomObject]$o }
    $rows = @(ConvertTo-M365TRLabeledRows -InputObject $flatSettings -LabelMap $labelMap)

    if ($rows.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Ustawienia grup Microsoft 365' -Status 'empty' `
            -Description 'Obiekt konfiguracji grup istnieje, ale nie zawiera żadnych ustawien.'
    }

    New-M365TRCollectorResult -Component 'EntraID' -Section 'Ustawienia grup Microsoft 365' `
        -Description 'Ustawienia tworzenia, nazewnictwa i dostępu gości dla grup Microsoft 365 (Group.Unified).' `
        -Status 'ok' -Data $rows
}
