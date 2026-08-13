function Invoke-M365TRGraphWrite {
    <#
    .SYNOPSIS
    POST/PATCH helper for the one-time admin-setup flow (app registration + consent).
    Mirrors Invoke-M365TRGraphRequest's never-throw / classified-error contract, but this is
    a single-shot write, not a paginated collector read.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][ValidateSet('POST', 'PATCH')][string]$Method,
        [Parameter(Mandatory)]$Body,
        [switch]$Beta
    )

    if ($Context.Token.ExpiresOn.LocalDateTime -lt (Get-Date).AddMinutes(2)) {
        try {
            $Context.Token = Get-MsalToken -ClientId $Context.ClientId -Scopes $Context.Scopes -ErrorAction Stop
        } catch {
            Write-Warning "Odswiezenie tokenu nie powiodło się: $($_.Exception.Message)"
        }
    }

    $version = if ($Beta) { 'beta' } else { 'v1.0' }
    $base = $Context.GraphBase.TrimEnd('/')
    $url = "$base/$version$Path"
    $headers = @{
        Authorization  = "Bearer $($Context.Token.AccessToken)"
        Accept         = 'application/json'
        'Content-Type' = 'application/json'
    }
    $json = $Body | ConvertTo-Json -Depth 10 -Compress

    try {
        $response = Invoke-RestMethod -Uri $url -Headers $headers -Method $Method -Body $json -ErrorAction Stop
        [PSCustomObject]@{ Success = $true; Data = $response; Status = 'ok'; Message = $null }
    } catch {
        $classified = Resolve-M365TRGraphError -ErrorRecord $_
        [PSCustomObject]@{ Success = $false; Data = $null; Status = $classified.Status; Message = $classified.Message }
    }
}
