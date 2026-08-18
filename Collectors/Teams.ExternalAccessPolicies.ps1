function Get-M365TRTeamsExternalAccessPolicyLabelMap {
    param([ValidateSet('pl', 'en')][string]$Language = 'pl')
    if ($Language -eq 'en') {
        return @{
            EnableFederationAccess       = 'Communication with other organizations allowed'
            EnableTeamsConsumerAccess    = 'Communication with Teams consumer accounts allowed'
            EnableTeamsConsumerInbound   = 'Inbound invitations from Teams consumer accounts allowed'
            EnablePublicCloudAccess      = 'Communication with Skype (public) accounts allowed'
            EnableAcsFederationAccess    = 'Communication with Azure Communication Services allowed'
            EnableXFederatedUsersAccess  = 'Communication with users on other Microsoft 365 clouds allowed'
            EnableFederationAccessSharedSipAddressSpace = 'Access allowed with shared SIP address space'
            Description                 = 'Admin description'
        }
    }
    return @{
        EnableFederationAccess       = 'Komunikacja z innymi organizacjami dozwolona'
        EnableTeamsConsumerAccess    = 'Komunikacja z kontami prywatnymi Teams dozwolona'
        EnableTeamsConsumerInbound   = 'Przychodzące zaproszenia od kont prywatnych Teams dozwolone'
        EnablePublicCloudAccess      = 'Komunikacja z kontami Skype (publiczne) dozwolona'
        EnableAcsFederationAccess    = 'Komunikacja z Azure Communication Services dozwolona'
        EnableXFederatedUsersAccess  = 'Komunikacja z użytkownikami innych chmur Microsoft 365 dozwolona'
        EnableFederationAccessSharedSipAddressSpace = 'Dostęp dozwolony przy współdzielonej przestrzeni adresów SIP'
        Description                 = 'Opis administratora'
    }
}

function Get-Collector_Teams_ExternalAccessPolicies {
    <#
    .SYNOPSIS
    Zasady dostępu zewnętrznego Microsoft Teams (per-zasada) - czy dany użytkownik/grupa może
    komunikować się z innymi organizacjami, kontami prywatnymi Teams/Skype, Azure Communication
    Services.
    #>
    param([Parameter(Mandatory)]$Context)
    $lang = Get-M365TRLanguage -Context $Context
    $description = if ($lang -eq 'en') {
        'Microsoft Teams external access policies (federation, consumer accounts, Azure Communication Services) per assignment - full settings for each policy.'
    } else {
        'Zasady dostępu zewnętrznego Microsoft Teams (federacja, konta prywatne, Azure Communication Services) per przypisanie - pełny zrzut ustawień każdej zasady.'
    }
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-CsExternalAccessPolicy }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Teams' -Section 'Zasady dostępu zewnętrznego' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Teams' -Section 'Zasady dostępu zewnętrznego' -Status 'empty' -Description $description
    }

    $labelMap = Get-M365TRTeamsExternalAccessPolicyLabelMap -Language $lang
    $excludeProps = @('Identity', 'Key', 'RunspaceId', 'PSComputerName', 'PSShowComputerName', 'Element', 'CimClass', 'CimInstanceProperties', 'CimSystemProperties')

    $records = $r.Data | ForEach-Object {
        $settingsRows = @(ConvertTo-M365TRLabeledRows -InputObject $_ -LabelMap $labelMap -ExcludeProperties $excludeProps -Language $lang)
        New-M365TRDetailRecord -Name $_.Identity -Tables @(
            (New-M365TRDetailTable -Title 'Ustawienia' -Rows $settingsRows)
        )
    }
    New-M365TRCollectorResult -Component 'Teams' -Section 'Zasady dostępu zewnętrznego' `
        -Description $description -Status 'ok' -Records -Data $records
}
