function Get-Collector_Purview_RightsManagementConfig {
    <#
    .SYNOPSIS
    Czy usługa ochrony praw do informacji (Azure RMS/IRM) jest aktywowana na poziomie tenanta -
    to warunek wstępny dzialania szyfrowania w etykietach poufności (bez tego etykiety z akcja
    "szyfrowanie" nie zadziałają, nawet jeśli są poprawnie skonfigurowane).
    #>
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-IRMConfiguration }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Purview' -Section 'Ochrona praw do informacji (RMS/IRM)' -Status $r.Status -Message $r.Message
    }
    $cfg = $r.Data | Select-Object -First 1
    if (-not $cfg) {
        return New-M365TRCollectorResult -Component 'Purview' -Section 'Ochrona praw do informacji (RMS/IRM)' -Status 'empty' `
            -Description 'Czy usługa ochrony praw do informacji (Azure RMS) jest aktywowana na poziomie tenanta - warunek działania szyfrowania w etykietach poufności.'
    }

    $rows = foreach ($x in @(
            [PSCustomObject]@{ 'Ustawienie' = 'Usługa Azure RMS (szyfrowanie treści)'; 'Wartość' = if ($cfg.AzureRMSLicensingEnabled) { 'Aktywowana' } else { 'Nieaktywowana' } }
            [PSCustomObject]@{ 'Ustawienie' = 'Licencjonowanie dla odbiorców wewnętrznych'; 'Wartość' = if ($cfg.InternalLicensingEnabled) { 'Włączone' } else { 'Wyłączone' } }
            [PSCustomObject]@{ 'Ustawienie' = 'Licencjonowanie dla odbiorców zewnętrznych'; 'Wartość' = if ($cfg.ExternalLicensingEnabled) { 'Włączone' } else { 'Wyłączone' } }
            [PSCustomObject]@{ 'Ustawienie' = 'Wyszukiwanie w zaszyfrowanych wiadomościach (indeksowanie)'; 'Wartość' = if ($cfg.SearchEnabled) { 'Włączone' } else { 'Wyłączone' } }
            [PSCustomObject]@{ 'Ustawienie' = 'Odszyfrowywanie na potrzeby dziennika (Journal Report Decryption)'; 'Wartość' = if ($cfg.JournalReportDecryptionEnabled) { 'Włączone' } else { 'Wyłączone' } }
            [PSCustomObject]@{ 'Ustawienie' = 'Dostęp super-użytkownika eDiscovery do zaszyfrowanej treści'; 'Wartość' = if ($cfg.EDiscoverySuperUserEnabled) { 'Włączony' } else { 'Wyłączony' } }
        )) { $x }
    $rows = @($rows)

    New-M365TRCollectorResult -Component 'Purview' -Section 'Ochrona praw do informacji (RMS/IRM)' `
        -Description 'Czy usługa ochrony praw do informacji (Azure RMS) jest aktywowana na poziomie tenanta - warunek działania szyfrowania w etykietach poufności.' `
        -Status 'ok' -Data $rows
}
