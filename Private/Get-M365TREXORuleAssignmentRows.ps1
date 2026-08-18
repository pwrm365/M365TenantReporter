function Get-M365TREXORuleAssignmentRows {
    <#
    .SYNOPSIS
    EXO mail-flow-style policies (Anti-Phish, Anti-Spam, Anti-Malware, Safe Links, Safe
    Attachments) have no Graph-style /assignments - scoping lives on a separate linked
    Get-XxxRule cmdlet (recipient/domain/group conditions, exceptions, priority). This turns
    one such rule object into "Przypisania" rows, or an explicit "no rule / not scoped" row
    when the policy has no linked rule (i.e. it's not currently applied to anyone).
    #>
    [CmdletBinding()]
    param($Rule, [ValidateSet('pl', 'en')][string]$Language = 'pl')

    $rows = New-Object System.Collections.Generic.List[object]

    if (-not $Rule) {
        $label = if ($Language -eq 'en') { 'Scope' } else { 'Zasięg' }
        $value = if ($Language -eq 'en') {
            'No rule linked to this policy - not currently applied to any recipients'
        } else {
            'Brak reguły powiązanej z tą zasadą - obecnie niestosowana do żadnych odbiorców'
        }
        $rows.Add([PSCustomObject]@{ 'Ustawienie' = $label; 'Wartość' = $value })
        return $rows
    }

    if ($Language -eq 'en') {
        $lbl = @{
            Include  = 'Recipients (include)'
            IncludeG = 'Recipient groups (include)'
            IncludeD = 'Recipient domains (include)'
            Exclude  = 'Recipients (exclude)'
            ExcludeG = 'Recipient groups (exclude)'
            ExcludeD = 'Recipient domains (exclude)'
            Prio     = 'Rule priority'
            State    = 'Rule state'
            Everyone = 'Everyone (no restricting conditions)'
        }
    } else {
        $lbl = @{
            Include  = 'Odbiorcy (dołącz)'
            IncludeG = 'Grupy odbiorców (dołącz)'
            IncludeD = 'Domeny odbiorców (dołącz)'
            Exclude  = 'Odbiorcy (wyklucz)'
            ExcludeG = 'Grupy odbiorców (wyklucz)'
            ExcludeD = 'Domeny odbiorców (wyklucz)'
            Prio     = 'Priorytet reguły'
            State    = 'Stan reguły'
            Everyone = 'Wszyscy odbiorcy (brak warunków ograniczających)'
        }
    }

    $addIf = {
        param($Label, $Value)
        $arr = @($Value) | Where-Object { $_ }
        if ($arr.Count -gt 0) {
            $rows.Add([PSCustomObject]@{ 'Ustawienie' = $Label; 'Wartość' = ($arr -join ', ') })
        }
    }
    & $addIf $lbl.Include $Rule.SentTo
    & $addIf $lbl.IncludeG $Rule.SentToMemberOf
    & $addIf $lbl.IncludeD $Rule.RecipientDomainIs
    & $addIf $lbl.Exclude $Rule.ExceptIfSentTo
    & $addIf $lbl.ExcludeG $Rule.ExceptIfSentToMemberOf
    & $addIf $lbl.ExcludeD $Rule.ExceptIfRecipientDomainIs

    if ($rows.Count -eq 0) {
        $rows.Add([PSCustomObject]@{ 'Ustawienie' = $lbl.Everyone; 'Wartość' = if ($Language -eq 'en') { 'Applies to all recipients' } else { 'Dotyczy wszystkich odbiorców' } })
    }
    $rows.Add([PSCustomObject]@{ 'Ustawienie' = $lbl.Prio; 'Wartość' = "$($Rule.Priority)" })
    $rows.Add([PSCustomObject]@{ 'Ustawienie' = $lbl.State; 'Wartość' = "$($Rule.State)" })

    return $rows
}
