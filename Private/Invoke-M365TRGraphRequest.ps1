function Invoke-M365TRGraphRequest {
    <#
    .SYNOPSIS
    The one and only place that talks to Microsoft Graph. Never throws - every failure mode
    (permission, license, not-found, throttling, transient) is caught, classified and returned
    as data so a single bad endpoint can never abort a collection run.
    .OUTPUTS
    PSCustomObject: Success, StatusCode, ErrorCode, Status (ok|empty|skipped-permission|skipped-license|error), Message, Data (array)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Context,
        [Parameter(Mandatory)][string]$Path,
        [switch]$Beta,
        [int]$MaxRetries = 5
    )

    if ($Context.Token.ExpiresOn.LocalDateTime -lt (Get-Date).AddMinutes(2)) {
        try {
            $Context.Token = Get-MsalToken -ClientId $Context.ClientId -Scopes $Context.Scopes -ErrorAction Stop
        } catch {
            Write-Warning "Odswiezenie tokenu nie powiodło się, kontynuuje ze starym tokenem: $($_.Exception.Message)"
        }
    }

    $version = if ($Beta) { 'beta' } else { 'v1.0' }
    $base = $Context.GraphBase.TrimEnd('/')
    $url = if ($Path -match '^https?://') { $Path } else { "$base/$version$Path" }

    $allItems = @()
    $singleObject = $null
    $isCollection = $false

    while ($url) {
        $attempt = 0
        $lastError = $null
        $response = $null
        while ($attempt -le $MaxRetries) {
            $attempt++
            try {
                $headers = @{
                    Authorization = "Bearer $($Context.Token.AccessToken)"
                    Accept        = 'application/json'
                }
                $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get -ErrorAction Stop
                $lastError = $null
                break
            } catch {
                $lastError = $_
                $statusCode = $null
                try { $statusCode = [int]$_.Exception.Response.StatusCode } catch {}
                if (($statusCode -eq 429 -or $statusCode -eq 503) -and $attempt -le $MaxRetries) {
                    $retryAfter = 2
                    try {
                        $h = $_.Exception.Response.Headers['Retry-After']
                        if ($h) { $retryAfter = [int]$h }
                    } catch {}
                    Write-Warning "Graph zwrocil $statusCode - ponawiam za $retryAfter s (proba $attempt/$MaxRetries): $url"
                    Start-Sleep -Seconds $retryAfter
                    continue
                }
                break
            }
        }

        if ($lastError) {
            $classified = Resolve-M365TRGraphError -ErrorRecord $lastError
            return [PSCustomObject]@{
                Success    = $false
                StatusCode = $classified.StatusCode
                ErrorCode  = $classified.ErrorCode
                Status     = $classified.Status
                Message    = $classified.Message
                Data       = @()
            }
        }

        if ($null -ne $response -and $null -ne $response.value) {
            $isCollection = $true
            $allItems += @($response.value)
            $url = $response.'@odata.nextLink'
        } else {
            $singleObject = $response
            $url = $null
        }
    }

    $data = if ($isCollection) { $allItems } elseif ($null -eq $singleObject) { @() } else { @($singleObject) }

    [PSCustomObject]@{
        Success    = $true
        StatusCode = 200
        ErrorCode  = $null
        Status     = 'ok'
        Message    = $null
        Data       = $data
    }
}
