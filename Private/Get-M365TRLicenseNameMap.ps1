function Get-M365TRLicenseNameMap {
    <#
    .SYNOPSIS
    Pobiera oficjalny, publikowany przez Microsoft plik CSV "Product names and service plan
    identifiers for licensing" i zwraca mapowanie String_Id (skuPartNumber, np. "SPE_E3") na
    przyjazna nazwę produktu (np. "Microsoft 365 E3"). Wynik jest cache'owany lokalnie (30 dni),
    żeby nie pobierac pliku przy każdym uruchomieniu. Nigdy nie rzuca wyjatku - przy braku
    internetu/pliku zwraca to, co jest w cache, albo pusta mape.
    #>
    [CmdletBinding()]
    param(
        [string]$CachePath = (Join-Path (Split-Path $PSScriptRoot -Parent) '.cache\ProductNames.csv'),
        [int]$MaxCacheAgeDays = 30
    )

    $url = 'https://download.microsoft.com/download/e/3/e/e3e9faf2-f28b-490a-9ada-c6089a1fc5b0/Product%20names%20and%20service%20plan%20identifiers%20for%20licensing.csv'
    $cacheDir = Split-Path -Parent $CachePath
    $needsDownload = $true
    if (Test-Path -LiteralPath $CachePath) {
        $age = (Get-Date) - (Get-Item -LiteralPath $CachePath).LastWriteTime
        if ($age.TotalDays -lt $MaxCacheAgeDays) { $needsDownload = $false }
    }

    if ($needsDownload) {
        try {
            if (-not (Test-Path -LiteralPath $cacheDir)) { New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null }
            Invoke-WebRequest -Uri $url -OutFile $CachePath -UseBasicParsing -TimeoutSec 20 -ErrorAction Stop
        } catch {
            Write-Warning "Nie udało się pobrac oficjalnej listy nazw licencji Microsoft (uzyje lokalnego cache/wbudowanej listy): $($_.Exception.Message)"
        }
    }

    $map = @{}
    if (Test-Path -LiteralPath $CachePath) {
        try {
            $rows = Import-Csv -LiteralPath $CachePath -ErrorAction Stop
            foreach ($row in $rows) {
                $sku = $row.String_Id
                $name = $row.Product_Display_Name
                if ($sku -and $name -and -not $map.ContainsKey($sku)) { $map[$sku] = $name }
            }
        } catch {
            Write-Warning "Nie udało się odczytać cache nazw licencji: $($_.Exception.Message)"
        }
    }
    return $map
}
