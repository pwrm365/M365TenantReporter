function ConvertTo-M365TRHtmlEncoded {
    <#
    .SYNOPSIS
    Minimal, dependency-free HTML encoding (avoids requiring System.Web on PowerShell 7).
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)][AllowNull()][AllowEmptyString()][string]$Text
    )
    process {
        if ($null -eq $Text) { return '' }
        $Text.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;')
    }
}
