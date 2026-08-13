function Get-Collector_Intune_DeviceManagementScripts {
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/deviceManagement/deviceManagementScripts' -Beta
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Intune' -Section 'Skrypty PowerShell (Device Management Scripts)' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Intune' -Section 'Skrypty PowerShell (Device Management Scripts)' -Status 'empty' `
            -Description 'Skrypty PowerShell (Device Management Scripts) przypisane do urządzeń w Intune.'
    }
    $flat = $r.Data | ForEach-Object {
        [PSCustomObject]@{
            'Nazwa'             = $_.displayName
            'Opis'              = $_.description
            'KontoUruchomienia' = $_.runAsAccount
        }
    }
    New-M365TRCollectorResult -Component 'Intune' -Section 'Skrypty PowerShell (Device Management Scripts)' `
        -Description 'Skrypty PowerShell (Device Management Scripts) przypisane do urządzeń w Intune.' -Status 'ok' -Data $flat
}
