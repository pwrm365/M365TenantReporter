function Get-Collector_Exchange_OrganizationConfig {
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-OrganizationConfig }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Konfiguracja organizacji' -Status $r.Status -Message $r.Message
    }
    $org = $r.Data | Select-Object -First 1
    $flat = [PSCustomObject]@{
        'Nazwa'                       = $org.Name
        'Nazwa wyswietlana'           = $org.DisplayName
        'Zdehydratowana'              = $org.IsDehydrated
        'OAuth2 włączony'             = $org.OAuth2ClientProfileEnabled
        'Identyfikator uslug online'  = $org.MicrosoftOnlineServicesID
    }
    New-M365TRCollectorResult -Component 'Exchange' -Section 'Konfiguracja organizacji' `
        -Description 'Globalna konfiguracja organizacji Exchange Online.' -Status 'ok' -Data @($flat) -Transpose
}
