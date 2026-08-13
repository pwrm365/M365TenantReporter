function Get-Collector_EntraID_TermsOfUse {
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/identityGovernance/termsOfUse/agreements'
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Warunki korzystania (Terms of Use)' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Warunki korzystania (Terms of Use)' -Status 'empty' `
            -Description 'Warunki korzystania (Terms of Use), które użytkownicy muszą zaakceptować.'
    }
    $flat = $r.Data | ForEach-Object {
        [PSCustomObject]@{
            'Nazwa'               = $_.displayName
            'WymaganePrzejrzenie' = $_.isViewingBeforeAcceptanceRequired
        }
    }
    New-M365TRCollectorResult -Component 'EntraID' -Section 'Warunki korzystania (Terms of Use)' `
        -Description 'Warunki korzystania (Terms of Use), które użytkownicy muszą zaakceptować.' -Status 'ok' -Data $flat
}
