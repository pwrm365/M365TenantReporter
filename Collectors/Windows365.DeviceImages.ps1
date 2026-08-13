function Get-Collector_Windows365_DeviceImages {
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/deviceManagement/virtualEndpoint/deviceImages' -Beta
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Windows365' -Section 'Obrazy urządzeń Cloud PC' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Windows365' -Section 'Obrazy urządzeń Cloud PC' -Status 'empty' `
            -Description 'Obrazy urządzeń (Device Images) dostępne do wdrożenia na Cloud PC.'
    }
    $flat = $r.Data | ForEach-Object {
        [PSCustomObject]@{
            'Nazwa'            = $_.displayName
            'SystemOperacyjny' = $_.operatingSystem
            'Status'           = $_.status
        }
    }
    New-M365TRCollectorResult -Component 'Windows365' -Section 'Obrazy urządzeń Cloud PC' `
        -Description 'Obrazy urządzeń (Device Images) dostępne do wdrożenia na Cloud PC.' -Status 'ok' -Data $flat
}
