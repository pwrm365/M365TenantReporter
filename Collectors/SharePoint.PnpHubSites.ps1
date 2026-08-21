function Get-Collector_SharePoint_PnpHubSites {
    <#
    .SYNOPSIS
    Witryny Hub SharePoint - centralne witryny grupujące powiązane witryny zespołów/komunikacji
    pod wspólną nawigacją i wyszukiwaniem. Liczba powiązanych witryn jest dociągana per hub -
    jeśli się nie powiedzie (np. przez zmianę składni filtra w nowszej wersji PnP.PowerShell),
    wiersz po prostu nie pokazuje liczby, zamiast wywalać cały kolektor.
    #>
    param([Parameter(Mandatory)]$Context)
    $lang = Get-M365TRLanguage -Context $Context
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-PnPHubSite }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'SharePoint' -Section 'Witryny Hub' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        $emptyDescription = if ($lang -eq 'en') { 'Hub sites configured in SharePoint - central sites that group related team/communication sites under shared navigation and search.' } else { 'Witryny Hub skonfigurowane w SharePoint - centralne witryny grupujące powiązane witryny zespołów/komunikacji pod wspólną nawigacją i wyszukiwaniem.' }
        return New-M365TRCollectorResult -Component 'SharePoint' -Section 'Witryny Hub' -Status 'empty' -Description $emptyDescription
    }

    $flat = $r.Data | ForEach-Object {
        $hub = $_
        $siteUrl = if ($hub.SiteUrl) { "$($hub.SiteUrl)" } else { "$($hub.SiteURL)" }
        $associatedCount = $null
        try {
            $assocResult = Invoke-M365TREXOCommand -ScriptBlock { Get-PnPTenantSite -Filter "HubSiteId -eq '$($hub.ID)'" -ErrorAction Stop }
            if ($assocResult.Success) { $associatedCount = @($assocResult.Data).Count }
        } catch {}
        [PSCustomObject]@{
            'Nazwa'                = "$($hub.Title)"
            'Adres URL'            = $siteUrl
            'Opis'                 = "$($hub.Description)"
            'Liczba powiązanych witryn' = if ($null -ne $associatedCount) { $associatedCount } else { if ($lang -eq 'en') { 'unknown' } else { 'nieznana' } }
        }
    }

    $description = if ($lang -eq 'en') {
        'Hub sites configured in SharePoint - central sites that group related team/communication sites under shared navigation and search.'
    } else {
        'Witryny Hub skonfigurowane w SharePoint - centralne witryny grupujące powiązane witryny zespołów/komunikacji pod wspólną nawigacją i wyszukiwaniem.'
    }
    New-M365TRCollectorResult -Component 'SharePoint' -Section 'Witryny Hub' -Description $description -Status 'ok' -Data $flat
}
