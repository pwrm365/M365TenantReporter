$Private = Get-ChildItem -Path "$PSScriptRoot\Private" -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue
$Public  = Get-ChildItem -Path "$PSScriptRoot\Public" -Filter '*.ps1' -ErrorAction SilentlyContinue

foreach ($file in @($Private) + @($Public)) {
    . $file.FullName
}

Export-ModuleMember -Function $Public.BaseName
