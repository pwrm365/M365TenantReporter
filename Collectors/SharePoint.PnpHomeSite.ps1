function Get-Collector_SharePoint_PnpHomeSite {
    <#
    .SYNOPSIS
    Witryna startowa (Home Site) SharePoint - główny punkt wejścia intranetu organizacji, jeśli
    skonfigurowany. Brak skonfigurowanej witryny startowej jest normalnym stanem w wielu
    tenantach (funkcja opcjonalna) - pojawi się jako pusta sekcja, nie błąd.
    #>
    param([Parameter(Mandatory)]$Context)
    $lang = Get-M365TRLanguage -Context $Context
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-PnPHomeSite }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'SharePoint' -Section 'Witryna startowa (Home Site)' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        $emptyDescription = if ($lang -eq 'en') { 'The SharePoint home site (organization intranet landing page), if configured.' } else { 'Witryna startowa (Home Site) SharePoint - główny punkt wejścia intranetu organizacji, jeśli skonfigurowany.' }
        return New-M365TRCollectorResult -Component 'SharePoint' -Section 'Witryna startowa (Home Site)' -Status 'empty' -Description $emptyDescription
    }

    $excludeProps = @('PSComputerName', 'PSShowComputerName', 'RunspaceId')
    $flat = $r.Data | ForEach-Object {
        @(ConvertTo-M365TRLabeledRows -InputObject $_ -ExcludeProperties $excludeProps -Language $lang)
    }

    $description = if ($lang -eq 'en') {
        'The SharePoint home site (organization intranet landing page) - the main entry point employees see, if configured.'
    } else {
        'Witryna startowa (Home Site) SharePoint - główny punkt wejścia intranetu organizacji, jeśli skonfigurowany.'
    }
    New-M365TRCollectorResult -Component 'SharePoint' -Section 'Witryna startowa (Home Site)' -Description $description -Status 'ok' -Data $flat
}
