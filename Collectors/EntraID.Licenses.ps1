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
    return $SkuPartNumber
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
