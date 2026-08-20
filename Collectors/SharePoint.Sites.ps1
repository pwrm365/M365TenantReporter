function Get-Collector_SharePoint_Sites {
    <#
    .SYNOPSIS
    Inwentarz witryn SharePoint (bez osobistych witryn OneDrive) - nazwa i adres. Microsoft Graph
    nie udostępnia w wynikach wyszukiwania witryn informacji o szablonie, rozmiarze, ani o tym czy
    dana witryna jest witryną hub - a dociąganie tego per-witryna byłoby kosztowne (N zapytań) przy
    dużej liczbie witryn. Pełny obraz (Home Site, powiązania hub-spoke, rozmiar, ustawienia dostępu)
    wymaga SharePoint Online Management Shell, którego to narzędzie obecnie nie używa.
    #>
    param([Parameter(Mandatory)]$Context)
    $lang = Get-M365TRLanguage -Context $Context
    $r = Invoke-M365TRGraphRequest -Context $Context -Path "/sites?search=*&`$select=displayName,webUrl,isPersonalSite"
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'SharePoint' -Section 'Inwentarz witryn' -Status $r.Status -Message $r.Message
    }
    $sites = @($r.Data | Where-Object { -not $_.isPersonalSite })
    if ($sites.Count -eq 0) {
        $emptyDescription = if ($lang -eq 'en') { 'Inventory of SharePoint sites (excluding personal OneDrive sites) - name and URL.' } else { 'Inwentarz witryn SharePoint (bez osobistych witryn OneDrive) - nazwa i adres.' }
        return New-M365TRCollectorResult -Component 'SharePoint' -Section 'Inwentarz witryn' -Status 'empty' -Description $emptyDescription
    }

    $maxShown = 200
    $shown = @($sites | Sort-Object displayName | Select-Object -First $maxShown)
    $rows = $shown | ForEach-Object {
        [PSCustomObject]@{
            'Nazwa'     = $_.displayName
            'Adres URL' = $_.webUrl
        }
    }

    $baseDescription = if ($lang -eq 'en') {
        'Inventory of SharePoint sites (excluding personal OneDrive sites).'
    } else {
        'Inwentarz witryn SharePoint (bez osobistych witryn OneDrive).'
    }
    $note = if ($sites.Count -gt $maxShown) {
        if ($lang -eq 'en') { " Showing $maxShown of $($sites.Count) sites (the rest were omitted to keep the report readable)." }
        else { " Pokazano $maxShown z $($sites.Count) witryn (pominięto pozostałe, żeby raport pozostał czytelny)." }
    } else { '' }
    $trailer = if ($lang -eq 'en') {
        ' Full details (Home Site, hub-spoke associations) require SharePoint Online Management Shell.'
    } else {
        ' Pełne informacje o witrynie startowej (Home Site) i powiązaniach hub-spoke wymagają SharePoint Online Management Shell.'
    }

    New-M365TRCollectorResult -Component 'SharePoint' -Section 'Inwentarz witryn' `
        -Description "$baseDescription$note$trailer" `
        -Status 'ok' -Data @($rows)
}
