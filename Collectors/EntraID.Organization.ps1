function Get-Collector_EntraID_Organization {
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/organization'
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Organizacja' -Status $r.Status -Message $r.Message
    }
    $org = $r.Data | Select-Object -First 1
    $flat = [PSCustomObject]@{
        'Nazwa'                 = $org.displayName
        'Domena podstawowa'     = ($org.verifiedDomains | Where-Object { $_.isDefault } | Select-Object -First 1 -ExpandProperty name)
        'Liczba domen'          = $org.verifiedDomains.Count
        'Kraj'                  = $org.countryLetterCode
        'Data utworzenia'       = $org.createdDateTime
        'Identyfikator tenanta' = $org.id
    }
    New-M365TRCollectorResult -Component 'EntraID' -Section 'Organizacja' `
        -Description 'Podstawowe informacje o tenancie.' -Status 'ok' -Data @($flat) -Transpose
}
