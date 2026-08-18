function ConvertTo-M365TRHumanizedSkuName {
    <#
    .SYNOPSIS
    Last-resort fallback when a skuPartNumber is in neither Microsoft's official CSV
    (Get-M365TRLicenseNameMap) nor the small built-in map below - happens for brand-new SKUs
    (e.g. Microsoft Entra Suite at GA) and partner-only trial/sandbox SKUs that Microsoft's
    public licensing CSV doesn't document at all. Splits the ALL_CAPS_WITH_UNDERSCORES /
    Mixed_Case_With_Underscores identifier into title-cased words so the report never shows a
    raw internal code, even though it's still a best-effort guess rather than the official name.
    #>
    param([string]$SkuPartNumber)
    # Niektóre SKU sklejają litery z cyframi bez podkreślenia (np. "MICROSOFT365") - rozdzielamy
    # też na granicy litera/cyfra, żeby nie zostawić "Microsoft365" zamiast "Microsoft 365".
    $words = ($SkuPartNumber -split '_' | Where-Object { $_ } | ForEach-Object {
        ($_ -split '(?<=[A-Za-z])(?=\d)|(?<=\d)(?=[A-Za-z])') | Where-Object { $_ }
    })
    if (@($words).Count -eq 0) { return $SkuPartNumber }
    return ($words | ForEach-Object {
        if ($_ -match '^\d+$') { $_ } else { (Get-Culture).TextInfo.ToTitleCase($_.ToLowerInvariant()) }
    }) -join ' '
}

function Get-M365TRFriendlyLicenseName {
    param([string]$SkuPartNumber, [hashtable]$OfficialMap = @{})
    if ($OfficialMap.ContainsKey($SkuPartNumber)) { return $OfficialMap[$SkuPartNumber] }
    $map = @{
        'SPE_E3'                 = 'Microsoft 365 E3'
        'SPE_E5'                 = 'Microsoft 365 E5'
        'SPB'                    = 'Microsoft 365 Business Premium'
        'O365_BUSINESS_PREMIUM'  = 'Microsoft 365 Business Standard'
        'O365_BUSINESS_ESSENTIALS' = 'Microsoft 365 Business Basic'
        'ENTERPRISEPACK'         = 'Office 365 E3'
        'ENTERPRISEPREMIUM'      = 'Office 365 E5'
        'ENTERPRISEWITHSCAL'     = 'Office 365 E4'
        'STANDARDPACK'           = 'Office 365 E1'
        'EXCHANGESTANDARD'       = 'Exchange Online (Plan 1)'
        'EXCHANGEENTERPRISE'     = 'Exchange Online (Plan 2)'
        'AAD_PREMIUM'            = 'Entra ID P1'
        'AAD_PREMIUM_P2'         = 'Entra ID P2'
        'EMS'                    = 'Enterprise Mobility + Security E3'
        'EMSPREMIUM'             = 'Enterprise Mobility + Security E5'
        'INTUNE_A'               = 'Intune'
        'POWER_BI_STANDARD'      = 'Power BI (bezplatny)'
        'POWER_BI_PRO'           = 'Power BI Pro'
        'FLOW_FREE'              = 'Power Automate (bezplatny)'
        'TEAMS_EXPLORATORY'      = 'Teams Exploratory'
        'MCOMEETADV'             = 'Microsoft 365 Audio Conferencing'
        'DEFENDER_ENDPOINT_P1'   = 'Defender for Endpoint P1'
        'DEFENDER_ENDPOINT_P2'   = 'Defender for Endpoint P2'
    }
    if ($map.ContainsKey($SkuPartNumber)) { return $map[$SkuPartNumber] }
    return ConvertTo-M365TRHumanizedSkuName $SkuPartNumber
}

function Get-Collector_EntraID_Licenses {
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/subscribedSkus'
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Licencje' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Licencje' -Status 'empty' `
            -Description 'Licencje (SKU) wykupione i przypisane w tenancie.'
    }
    $officialMap = Get-M365TRLicenseNameMap
    $flat = $r.Data | ForEach-Object {
        $enabled = $_.prepaidUnits.enabled
        $consumed = $_.consumedUnits
        [PSCustomObject]@{
            'Licencja'   = Get-M365TRFriendlyLicenseName -SkuPartNumber $_.skuPartNumber -OfficialMap $officialMap
            'Wykupione'  = $enabled
            'Przypisane' = $consumed
            'Wolne'      = [Math]::Max(0, $enabled - $consumed)
        }
    }
    New-M365TRCollectorResult -Component 'EntraID' -Section 'Licencje' `
        -Description 'Licencje (SKU) wykupione i przypisane w tenancie.' -Status 'ok' -Data $flat
}
