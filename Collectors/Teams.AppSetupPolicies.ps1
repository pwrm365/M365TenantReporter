function Get-M365TRTeamsAppSetupLabelMap {
    param([ValidateSet('pl', 'en')][string]$Language = 'pl')
    if ($Language -eq 'en') {
        return @{
            AllowSideLoading            = 'Custom app upload (sideloading) allowed'
            AllowUserPinning            = 'Users can pin their own apps'
            IsAppBarDragAndDropEnabled  = 'Users can rearrange the app bar'
            AppPresetList               = 'Pre-installed/pinned apps'
            Description                 = 'Admin description'
        }
    }
    return @{
        AllowSideLoading            = 'Wgrywanie własnych aplikacji (sideloading) dozwolone'
        AllowUserPinning            = 'Użytkownicy mogą przypinać własne aplikacje'
        IsAppBarDragAndDropEnabled  = 'Użytkownicy mogą zmieniać kolejność aplikacji na pasku'
        AppPresetList               = 'Aplikacje preinstalowane/przypięte'
        Description                 = 'Opis administratora'
    }
}

function Get-Collector_Teams_AppSetupPolicies {
    <#
    .SYNOPSIS
    Zasady konfiguracji aplikacji Microsoft Teams - czy użytkownicy mogą wgrywać własne
    (niepodpisane) aplikacje (sideloading), przypinać własne aplikacje, oraz jakie aplikacje są
    preinstalowane/przypięte domyślnie. Sideloading jest klasycznym wektorem obejścia kontroli
    administracyjnej nad aplikacjami.
    #>
    param([Parameter(Mandatory)]$Context)
    $lang = Get-M365TRLanguage -Context $Context
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-CsTeamsAppSetupPolicy }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Teams' -Section 'Zasady konfiguracji aplikacji' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        $emptyDescription = if ($lang -eq 'en') { 'Microsoft Teams app setup policies (custom app sideloading, user pinning, pre-installed apps).' } else { 'Zasady konfiguracji aplikacji Microsoft Teams (sideloading, przypinanie aplikacji, aplikacje preinstalowane).' }
        return New-M365TRCollectorResult -Component 'Teams' -Section 'Zasady konfiguracji aplikacji' -Status 'empty' -Description $emptyDescription
    }

    $labelMap = Get-M365TRTeamsAppSetupLabelMap -Language $lang
    $excludeProps = @('Identity', 'Key', 'RunspaceId', 'PSComputerName', 'PSShowComputerName', 'Element', 'CimClass', 'CimInstanceProperties', 'CimSystemProperties')

    $records = $r.Data | ForEach-Object {
        $settingsRows = @(ConvertTo-M365TRLabeledRows -InputObject $_ -LabelMap $labelMap -ExcludeProperties $excludeProps -Language $lang)
        New-M365TRDetailRecord -Name $_.Identity -Tables @(
            (New-M365TRDetailTable -Title 'Ustawienia' -Rows $settingsRows)
        )
    }

    $description = if ($lang -eq 'en') {
        'Microsoft Teams app setup policies - whether users can upload custom (unsigned) apps (sideloading), pin their own apps, and which apps are pre-installed/pinned by default. Sideloading is a classic way to bypass admin control over which apps run.'
    } else {
        'Zasady konfiguracji aplikacji Microsoft Teams - czy użytkownicy mogą wgrywać własne (niepodpisane) aplikacje (sideloading), przypinać własne aplikacje, oraz jakie aplikacje są preinstalowane/przypięte domyślnie. Sideloading to klasyczny sposób obejścia kontroli administracyjnej nad aplikacjami.'
    }
    New-M365TRCollectorResult -Component 'Teams' -Section 'Zasady konfiguracji aplikacji' -Description $description -Status 'ok' -Records -Data $records
}
