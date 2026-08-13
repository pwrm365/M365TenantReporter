function Get-Collector_EntraID_SecurityDefaults {
    <#
    .SYNOPSIS
    Czy w tenancie włączone są Security Defaults (bazowa, darmowa ochrona: wymuszone MFA dla
    administratorów i użytkowników, blokada starych protokołów uwierzytelniania). Security
    Defaults i Conditional Access wzajemnie się wykluczają - warto to widzieć obok siebie.
    #>
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/policies/identitySecurityDefaultsEnforcementPolicy'
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Security Defaults' -Status $r.Status -Message $r.Message
    }
    $pol = $r.Data | Select-Object -First 1
    if (-not $pol) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Security Defaults' -Status 'empty' `
            -Description 'Bazowa ochrona tożsamości Microsoft (Security Defaults) - wymuszone MFA, blokada starych protokołów uwierzytelniania.'
    }
    $rows = @([PSCustomObject]@{ 'Ustawienie' = 'Security Defaults'; 'Wartość' = if ($pol.isEnabled) { 'Włączone' } else { 'Wyłączone' } })
    New-M365TRCollectorResult -Component 'EntraID' -Section 'Security Defaults' `
        -Description 'Bazowa ochrona tożsamości Microsoft (Security Defaults) - wymuszone MFA, blokada starych protokołów uwierzytelniania. Wyklucza się wzajemnie z politykami Conditional Access.' `
        -Status 'ok' -Data $rows
}
