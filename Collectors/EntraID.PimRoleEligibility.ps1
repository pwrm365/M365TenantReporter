function Get-Collector_EntraID_PimRoleEligibility {
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/roleManagement/directory/roleEligibilityScheduleInstances'
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Uprawnienia PIM (Privileged Identity Management)' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Uprawnienia PIM (Privileged Identity Management)' -Status 'empty' `
            -Description 'Uprawnienia kwalifikowane (eligible) do rol uprzywilejowanych przyznane w ramach PIM.'
    }
    $flat = $r.Data | ForEach-Object {
        [PSCustomObject]@{
            'Podmiot'        = $_.principalId
            'Rola'           = $_.roleDefinitionId
            'ZakresKatalogu' = $_.directoryScopeId
        }
    }
    New-M365TRCollectorResult -Component 'EntraID' -Section 'Uprawnienia PIM (Privileged Identity Management)' `
        -Description 'Uprawnienia kwalifikowane (eligible) do rol uprzywilejowanych przyznane w ramach PIM.' -Status 'ok' -Data $flat
}
