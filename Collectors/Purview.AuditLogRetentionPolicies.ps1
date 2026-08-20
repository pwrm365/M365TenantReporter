function Get-Collector_Purview_AuditLogRetentionPolicies {
    <#
    .SYNOPSIS
    Zasady przechowywania rejestru audytu (Unified Audit Log Retention) - jak długo poszczególne
    typy zdarzeń audytowych są przechowywane. Bez niestandardowej zasady obowiązuje domyślny okres
    Microsoft (90 dni, lub dłużej z licencją E5/Compliance) - brak zasad jest normalnym stanem, nie
    błędem, i oznacza po prostu korzystanie z ustawień domyślnych.
    #>
    param([Parameter(Mandatory)]$Context)
    $lang = Get-M365TRLanguage -Context $Context
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-UnifiedAuditLogRetentionPolicy }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Purview' -Section 'Zasady przechowywania rejestru audytu' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        $emptyDescription = if ($lang -eq 'en') { 'Custom audit log retention policies configured in Microsoft Purview. No custom policy means the Microsoft default retention period applies.' } else { 'Niestandardowe zasady przechowywania rejestru audytu skonfigurowane w Microsoft Purview. Brak niestandardowej zasady oznacza obowiązywanie domyślnego okresu Microsoft.' }
        return New-M365TRCollectorResult -Component 'Purview' -Section 'Zasady przechowywania rejestru audytu' -Status 'empty' -Description $emptyDescription
    }

    $flat = $r.Data | ForEach-Object {
        [PSCustomObject]@{
            'Nazwa'                  = $_.Name
            'Priorytet'              = "$($_.Priority)"
            'Okres przechowywania (dni)' = "$($_.RetentionDuration)"
            'Obszar roboczy'         = (@($_.Workload) -join ', ')
            'Włączona'               = if ($_.Enabled) { $true } else { $false }
        }
    }

    $description = if ($lang -eq 'en') {
        'Custom audit log retention policies configured in Microsoft Purview - how long each type of audit event is kept beyond the Microsoft default.'
    } else {
        'Niestandardowe zasady przechowywania rejestru audytu skonfigurowane w Microsoft Purview - jak długo poszczególne typy zdarzeń audytowych są przechowywane ponad domyślny okres Microsoft.'
    }
    New-M365TRCollectorResult -Component 'Purview' -Section 'Zasady przechowywania rejestru audytu' -Description $description -Status 'ok' -Data $flat
}
