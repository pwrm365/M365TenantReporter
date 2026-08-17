function Get-Collector_Teams_ExternalAccessPolicies {
    <#
    .SYNOPSIS
    Zasady dostępu zewnętrznego Microsoft Teams (per-zasada) - czy dany użytkownik/grupa może
    komunikować się z innymi organizacjami, kontami prywatnymi Teams/Skype, Azure Communication
    Services.
    #>
    param([Parameter(Mandatory)]$Context)
    $lang = Get-M365TRLanguage -Context $Context
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-CsExternalAccessPolicy }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Teams' -Section 'Zasady dostępu zewnętrznego' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Teams' -Section 'Zasady dostępu zewnętrznego' -Status 'empty' `
            -Description 'Zasady dostępu zewnętrznego Microsoft Teams (federacja, konta prywatne, Azure Communication Services) per przypisanie.'
    }

    $flat = $r.Data | ForEach-Object {
        $parts = New-Object System.Collections.Generic.List[string]
        if ($lang -eq 'en') {
            if ($_.EnableFederationAccess -eq $true) { $parts.Add('communication with other organizations allowed') }
            if ($_.EnableTeamsConsumerAccess -eq $true) { $parts.Add('communication with Teams consumer accounts allowed') }
            if ($_.EnableTeamsConsumerInbound -eq $true) { $parts.Add('inbound invitations from Teams consumer accounts allowed') }
            if ($_.EnablePublicCloudAccess -eq $true) { $parts.Add('communication with Skype (public) accounts allowed') }
            if ($_.EnableAcsFederationAccess -eq $true) { $parts.Add('communication with Azure Communication Services allowed') }
            $summary = if ($parts.Count -gt 0) { $parts -join '; ' } else { '(everything blocked)' }
        } else {
            if ($_.EnableFederationAccess -eq $true) { $parts.Add('komunikacja z innymi organizacjami dozwolona') }
            if ($_.EnableTeamsConsumerAccess -eq $true) { $parts.Add('komunikacja z kontami prywatnymi Teams dozwolona') }
            if ($_.EnableTeamsConsumerInbound -eq $true) { $parts.Add('przychodzące zaproszenia od kont prywatnych Teams dozwolone') }
            if ($_.EnablePublicCloudAccess -eq $true) { $parts.Add('komunikacja z kontami Skype (publiczne) dozwolona') }
            if ($_.EnableAcsFederationAccess -eq $true) { $parts.Add('komunikacja z Azure Communication Services dozwolona') }
            $summary = if ($parts.Count -gt 0) { $parts -join '; ' } else { '(wszystko zablokowane)' }
        }

        [PSCustomObject]@{
            'Nazwa'   = $_.Identity
            'Co robi' = $summary
        }
    }
    New-M365TRCollectorResult -Component 'Teams' -Section 'Zasady dostępu zewnętrznego' `
        -Description 'Zasady dostępu zewnętrznego Microsoft Teams (federacja, konta prywatne, Azure Communication Services) per przypisanie.' -Status 'ok' -Data $flat
}
