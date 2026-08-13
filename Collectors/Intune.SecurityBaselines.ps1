function Get-Collector_Intune_SecurityBaselines {
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/deviceManagement/intents' -Beta
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Intune' -Section 'Bazowe konfiguracje zabezpieczeń (Security Baselines)' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Intune' -Section 'Bazowe konfiguracje zabezpieczeń (Security Baselines)' -Status 'empty' `
            -Description 'Bazowe konfiguracje zabezpieczeń (Security Baselines) oraz inne intencje (intents) Intune.'
    }
    $flat = $r.Data | ForEach-Object {
        [PSCustomObject]@{
            'Nazwa'    = $_.displayName
            'Opis'     = $_.description
            'SzablonId' = $_.templateId
        }
    }
    New-M365TRCollectorResult -Component 'Intune' -Section 'Bazowe konfiguracje zabezpieczeń (Security Baselines)' `
        -Description 'Bazowe konfiguracje zabezpieczeń (Security Baselines) oraz inne intencje (intents) Intune.' -Status 'ok' -Data $flat
}
