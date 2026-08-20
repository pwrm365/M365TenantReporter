function Resolve-M365TRGraphError {
    <#
    .SYNOPSIS
    Classifies a caught Graph API error into one of: empty | skipped-permission | skipped-license | error.
    Never throws - always returns a classification, even when the error shape is unexpected.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$ErrorRecord,
        [ValidateSet('pl', 'en')][string]$Language = 'pl'
    )

    $statusCode = $null
    try { $statusCode = [int]$ErrorRecord.Exception.Response.StatusCode } catch { $statusCode = $null }

    $errorCode = $null
    $errorMessage = $null
    try {
        if ($ErrorRecord.ErrorDetails.Message) {
            $body = $ErrorRecord.ErrorDetails.Message | ConvertFrom-Json
            $errorCode = $body.error.code
            $errorMessage = $body.error.message
        }
    } catch {
        # Body wasn't JSON or didn't parse - fall through with $errorCode/$errorMessage still $null.
    }
    if (-not $errorMessage) { $errorMessage = $ErrorRecord.Exception.Message }

    # Graph zwraca czasem 400 z "Resource not found for the segment '...'" zamiast 404,
    # gdy endpoint jest niedostępny dla tego tokenu/wersji API/tenanta - traktujemy to jak
    # brakujący zasob, a nie błąd naszego kodu.
    $isUnknownSegment = $errorMessage -match "Resource not found for the segment"

    $status = switch ($true) {
        { $statusCode -eq 404 -or $isUnknownSegment } { 'empty'; break }
        { $errorCode -eq 'Authorization_RequestDenied' -or $statusCode -eq 403 } { 'skipped-permission'; break }
        { $errorCode -eq 'AadPremiumLicenseRequired' -or $errorMessage -match 'Premium license' } { 'skipped-license'; break }
        { $statusCode -eq 401 } { 'skipped-permission'; break }
        default { 'error' }
    }

    $friendly = if ($Language -eq 'en') {
        switch ($status) {
            'skipped-permission' { "Missing consent/permission in Microsoft Graph (code: $errorCode)." }
            'skipped-license'    { "The tenant does not have the required license (Entra ID P2 / Governance)." }
            'empty'              {
                if ($isUnknownSegment) { "Endpoint not available for this token/API version in this tenant ($errorMessage)." }
                else { "The resource does not exist in this tenant." }
            }
            default              { "Graph API error ($statusCode $errorCode): $errorMessage" }
        }
    } else {
        switch ($status) {
            'skipped-permission' { "Brak zgody/uprawnienia w Microsoft Graph (kod: $errorCode)." }
            'skipped-license'    { "Tenant nie posiada wymaganej licencji (Entra ID P2 / Governance)." }
            'empty'              {
                if ($isUnknownSegment) { "Endpoint niedostępny dla tego tokenu/wersji API w tym tenancie ($errorMessage)." }
                else { "Zasob nie istnieje w tym tenancie." }
            }
            default              { "Błąd Graph API ($statusCode $errorCode): $errorMessage" }
        }
    }

    [PSCustomObject]@{
        Status     = $status
        StatusCode = $statusCode
        ErrorCode  = $errorCode
        Message    = $friendly
    }
}
