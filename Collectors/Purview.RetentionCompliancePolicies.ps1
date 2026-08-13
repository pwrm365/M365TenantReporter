function Get-M365TRRetentionCompliancePolicySummary {
    param($Policy)
    $parts = New-Object System.Collections.Generic.List[string]

    $scopeProps = 'Workload', 'ExchangeLocation', 'SharePointLocation', 'Locations', 'OneDriveLocation', 'ModernGroupLocation'
    $scopes = New-Object System.Collections.Generic.List[string]
    foreach ($prop in $scopeProps) {
        $val = $Policy.$prop
        if ($val -and @($val).Count -gt 0) {
            $joined = (@($val) | ForEach-Object { [string]$_ }) -join ', '
            if ($joined) { $scopes.Add($joined) }
        }
    }
    if ($scopes.Count -gt 0) { $parts.Add("zakres: $(($scopes | Select-Object -Unique) -join ', ')") }

    if ($Policy.Mode) { $parts.Add("tryb: $($Policy.Mode)") }

    if ($parts.Count -eq 0) { return '(brak kluczowych ustawien do podsumowania)' }
    return ($parts -join '; ')
}

function Get-Collector_Purview_RetentionCompliancePolicies {
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-RetentionCompliancePolicy }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Purview' -Section 'Zasady retencji' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Purview' -Section 'Zasady retencji' -Status 'empty' `
            -Description 'Zasady retencji danych skonfigurowane w Microsoft Purview.'
    }
    $flat = $r.Data | ForEach-Object {
        [PSCustomObject]@{
            'Nazwa'    = $_.Name
            'Włączona' = $_.Enabled
            'Co robi'  = Get-M365TRRetentionCompliancePolicySummary -Policy $_
        }
    }
    New-M365TRCollectorResult -Component 'Purview' -Section 'Zasady retencji' `
        -Description 'Zasady retencji danych skonfigurowane w Microsoft Purview.' -Status 'ok' -Data $flat
}
