function Get-Collector_Windows365_OnPremConnections {
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/deviceManagement/virtualEndpoint/onPremisesConnections' -Beta
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Windows365' -Section 'Połączenia on-premises (Cloud PC)' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Windows365' -Section 'Połączenia on-premises (Cloud PC)' -Status 'empty' `
            -Description 'Połączenia on-premises (Cloud PC) używane do laczenia Cloud PC z siecia firmowa.'
    }
    $flat = $r.Data | ForEach-Object {
        [PSCustomObject]@{
            'Nazwa'            = $_.displayName
            'StatusPolaczenia' = $_.healthCheckStatus
        }
    }
    New-M365TRCollectorResult -Component 'Windows365' -Section 'Połączenia on-premises (Cloud PC)' `
        -Description 'Połączenia on-premises (Cloud PC) używane do laczenia Cloud PC z siecia firmowa.' -Status 'ok' -Data $flat
}
