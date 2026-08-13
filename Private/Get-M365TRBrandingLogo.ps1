function Get-M365TRBrandingLogo {
    <#
    .SYNOPSIS
    Fetches the tenant's Entra ID company branding banner logo (if configured) as a base64
    data URI, for embedding in the report cover page. Returns $null gracefully - not every
    tenant configures custom branding, and this must never block report generation.
    .NOTES
    The dedicated Graph binary-fetch endpoint (/organization/{id}/branding/bannerLogo) is
    unreliable - it errors with "Invalid locale id value bannerLogo" regardless of tenant
    (verified live). The branding object itself, however, exposes bannerLogoRelativeUrl plus
    a list of CDN hosts (cdnList) - this is the same public, unauthenticated CDN Microsoft
    itself uses to serve the logo on the actual sign-in page, so we fetch it the same way.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Context
    )
    try {
        $orgResult = Invoke-M365TRGraphRequest -Context $Context -Path '/organization'
        if (-not $orgResult.Success -or $orgResult.Data.Count -eq 0) { return $null }
        $tenantId = $orgResult.Data[0].id

        $brandingResult = Invoke-M365TRGraphRequest -Context $Context -Path "/organization/$tenantId/branding"
        if (-not $brandingResult.Success -or $brandingResult.Data.Count -eq 0) { return $null }
        $branding = $brandingResult.Data[0]
        if (-not $branding.bannerLogoRelativeUrl -or @($branding.cdnList).Count -eq 0) { return $null }

        $cdnHost = $branding.cdnList[0]
        $logoUrl = "https://$cdnHost/$($branding.bannerLogoRelativeUrl)"
        $response = Invoke-WebRequest -Uri $logoUrl -Method Get -ErrorAction Stop

        if (-not $response.Content -or $response.Content.Length -eq 0) { return $null }

        $contentType = $response.Headers['Content-Type']
        if ($contentType -is [array]) { $contentType = $contentType[0] }
        if (-not $contentType -or $contentType -notmatch '^image/') { $contentType = 'image/png' }

        $base64 = [Convert]::ToBase64String($response.Content)
        return "data:$contentType;base64,$base64"
    } catch {
        Write-Warning "Logo organizacji (banner) niedostępne w tym tenancie: $($_.Exception.Message)"
        return $null
    }
}
