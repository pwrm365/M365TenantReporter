function Invoke-M365TREXOCommand {
    <#
    .SYNOPSIS
    The Exchange Online / Security & Compliance equivalent of Invoke-M365TRGraphRequest -
    wraps a native EXO/IPPS cmdlet call, never throws, and returns the same shape so
    Exchange/Purview collectors follow the identical resilience contract as Graph collectors.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][scriptblock]$ScriptBlock
    )
    try {
        $result = & $ScriptBlock
        [PSCustomObject]@{ Success = $true; Status = 'ok'; Message = $null; Data = @($result) }
    } catch {
        $msg = $_.Exception.Message
        $status = switch -Wildcard ($msg) {
            '*Access*denied*'               { 'skipped-permission'; break }
            '*not have permission*'         { 'skipped-permission'; break }
            '*Insufficient access rights*'  { 'skipped-permission'; break }
            '*not recognized as*cmdlet*'    { 'skipped-permission'; break } # sesja EXO/IPPS niepolaczona - cmdlet niedostępny
            '*status code is*Unauthorized*' { 'skipped-permission'; break } # PnP.PowerShell: polaczenie (cert) OK, ale brak Sites.FullControl.All
            default                         { 'error' }
        }
        [PSCustomObject]@{ Success = $false; Status = $status; Message = $msg; Data = @() }
    }
}
