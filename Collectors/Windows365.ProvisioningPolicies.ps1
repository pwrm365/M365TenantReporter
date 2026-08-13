function Get-Collector_Windows365_ProvisioningPolicies {
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/deviceManagement/virtualEndpoint/provisioningPolicies' -Beta
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Windows365' -Section 'Profile provisioningu' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Windows365' -Section 'Profile provisioningu' -Status 'empty' `
            -Description 'Profile provisioningu Windows 365 Cloud PC.'
    }
    $flat = $r.Data | ForEach-Object {
        [PSCustomObject]@{
            'Nazwa'      = $_.displayName
            'Typ obrazu' = $_.imageDisplayName
        }
    }
    New-M365TRCollectorResult -Component 'Windows365' -Section 'Profile provisioningu' `
        -Description 'Profile provisioningu Windows 365 Cloud PC.' -Status 'ok' -Data $flat
}
