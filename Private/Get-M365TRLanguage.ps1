function Get-M365TRLanguage {
    <#
    .SYNOPSIS
    Safely reads the report language ('pl'/'en') off a Context object. Defaults to 'pl' when the
    property is missing, null, or anything other than 'en' - collectors always get a valid value
    to pass into the bilingual formatting helpers, whether or not the caller set Language.
    #>
    [CmdletBinding()]
    param($Context)

    if ($Context -and ($Context.PSObject.Properties.Name -contains 'Language') -and $Context.Language -eq 'en') {
        return 'en'
    }
    return 'pl'
}
