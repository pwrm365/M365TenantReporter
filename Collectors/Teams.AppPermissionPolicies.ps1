function Get-M365TRTeamsAppPermissionLabelMap {
    param([ValidateSet('pl', 'en')][string]$Language = 'pl')
    if ($Language -eq 'en') {
        return @{
            GlobalCatalogAppsType  = 'Microsoft apps'
            DefaultCatalogAppsType = 'Third-party apps'
            PrivateCatalogAppsType = 'Custom (org-published) apps'
            Description            = 'Admin description'
        }
    }
    return @{
        GlobalCatalogAppsType  = 'Aplikacje Microsoft'
        DefaultCatalogAppsType = 'Aplikacje firm trzecich'
        PrivateCatalogAppsType = 'Aplikacje niestandardowe (opublikowane przez organizację)'
        Description            = 'Opis administratora'
    }
}

function Get-Collector_Teams_AppPermissionPolicies {
    <#
    .SYNOPSIS
    Zasady uprawnień aplikacji Microsoft Teams - czy aplikacje Microsoft, firm trzecich oraz
    niestandardowe (opublikowane przez organizację) są dozwolone globalnie, czy tylko z listy
    dozwolonych/zablokowanych. Kontroluje, jakie integracje mogą się w ogóle pojawić w Teams.
    #>
    param([Parameter(Mandatory)]$Context)
    $lang = Get-M365TRLanguage -Context $Context
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-CsTeamsAppPermissionPolicy }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Teams' -Section 'Zasady uprawnień aplikacji' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        $emptyDescription = if ($lang -eq 'en') { 'Microsoft Teams app permission policies (which Microsoft/third-party/custom apps are allowed).' } else { 'Zasady uprawnień aplikacji Microsoft Teams (jakie aplikacje Microsoft/firm trzecich/niestandardowe są dozwolone).' }
        return New-M365TRCollectorResult -Component 'Teams' -Section 'Zasady uprawnień aplikacji' -Status 'empty' -Description $emptyDescription
    }

    $labelMap = Get-M365TRTeamsAppPermissionLabelMap -Language $lang
    $excludeProps = @('Identity', 'Key', 'RunspaceId', 'PSComputerName', 'PSShowComputerName', 'Element', 'CimClass', 'CimInstanceProperties', 'CimSystemProperties', 'GlobalCatalogApps', 'DefaultCatalogApps', 'PrivateCatalogApps')

    $records = $r.Data | ForEach-Object {
        $settingsRows = @(ConvertTo-M365TRLabeledRows -InputObject $_ -LabelMap $labelMap -ExcludeProperties $excludeProps -Language $lang)
        New-M365TRDetailRecord -Name $_.Identity -Tables @(
            (New-M365TRDetailTable -Title 'Ustawienia' -Rows $settingsRows)
        )
    }

    $description = if ($lang -eq 'en') {
        'Microsoft Teams app permission policies - whether Microsoft, third-party, and custom (org-published) apps are allowed tenant-wide or restricted to an allow/block list.'
    } else {
        'Zasady uprawnień aplikacji Microsoft Teams - czy aplikacje Microsoft, firm trzecich i niestandardowe (opublikowane przez organizację) są dozwolone globalnie czy ograniczone do listy dozwolonych/zablokowanych.'
    }
    New-M365TRCollectorResult -Component 'Teams' -Section 'Zasady uprawnień aplikacji' -Description $description -Status 'ok' -Records -Data $records
}
