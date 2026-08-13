function Resolve-M365TRDnsTxt {
    param([string]$Name)
    $answers = $null
    try {
        $answers = Resolve-DnsName -Name $Name -Type TXT -Server 1.1.1.1 -DnsOnly -ErrorAction Stop
    } catch {
        try { $answers = Resolve-DnsName -Name $Name -Type TXT -DnsOnly -ErrorAction Stop } catch { return @() }
    }
    $texts = foreach ($a in @($answers)) {
        if ($a.Strings) { ($a.Strings -join '') }
    }
    return @($texts)
}

function Resolve-M365TRDnsCname {
    param([string]$Name)
    $answers = $null
    try {
        $answers = Resolve-DnsName -Name $Name -Type CNAME -Server 1.1.1.1 -DnsOnly -ErrorAction Stop
    } catch {
        try { $answers = Resolve-DnsName -Name $Name -Type CNAME -DnsOnly -ErrorAction Stop } catch { return $null }
    }
    $cname = @($answers) | Where-Object { $_.Type -eq 'CNAME' } | Select-Object -First 1
    if ($cname) { return $cname.NameHost }
    return $null
}

function Get-M365TRSpfSummary {
    param([string]$Domain)
    $txts = Resolve-M365TRDnsTxt -Name $Domain
    $spf = $txts | Where-Object { $_ -like 'v=spf1*' } | Select-Object -First 1
    if (-not $spf) { return 'Brak rekordu SPF' }

    $parts = New-Object System.Collections.Generic.List[string]
    if ($spf -match 'include:spf\.protection\.outlook\.com') { $parts.Add('zawiera Microsoft 365 (spf.protection.outlook.com)') }
    else { $parts.Add('nie zawiera Microsoft 365 (spf.protection.outlook.com)') }

    if ($spf -match '-all') { $parts.Add('zasada koncowa: twarda (-all)') }
    elseif ($spf -match '~all') { $parts.Add('zasada koncowa: miekka (~all)') }
    elseif ($spf -match '\?all') { $parts.Add('zasada koncowa: neutralna (?all)') }
    elseif ($spf -match '\+all') { $parts.Add('zasada koncowa: zezwol na wszystko (+all)') }
    else { $parts.Add('brak jawnej zasady koncowej (all)') }

    "SPF obecny; $($parts -join '; ')"
}

function Get-M365TRDmarcSummary {
    param([string]$Domain)
    $txts = Resolve-M365TRDnsTxt -Name "_dmarc.$Domain"
    $dmarc = $txts | Where-Object { $_ -like 'v=DMARC1*' } | Select-Object -First 1
    if (-not $dmarc) { return 'Brak rekordu DMARC' }

    $policy = if ($dmarc -match 'p=([^;]+)') { $Matches[1].Trim() } else { $null }
    $pct = if ($dmarc -match 'pct=([^;]+)') { $Matches[1].Trim() } else { $null }
    $rua = if ($dmarc -match 'rua=([^;]+)') { $Matches[1].Trim() } else { $null }

    $parts = New-Object System.Collections.Generic.List[string]
    if ($policy) { $parts.Add("polityka (p): $policy") }
    if ($pct -and $pct -ne '100') { $parts.Add("zakres (pct): $pct%") }
    if ($rua) { $parts.Add("raporty (rua): $rua") }

    "DMARC obecny; $($parts -join '; ')"
}

function Get-M365TRDkimSummary {
    param($Context, [string]$Domain)
    $dkimResult = Invoke-M365TREXOCommand -ScriptBlock { Get-DkimSigningConfig -Identity $Domain -ErrorAction Stop }

    $m365Part = if ($dkimResult.Success -and $dkimResult.Data.Count -gt 0) {
        $cfg = $dkimResult.Data[0]
        if ($cfg.Enabled -eq $true) { 'włączony w M365' } else { 'wyłączony w M365' }
    } else { 'brak konfiguracji DKIM w M365 dla tej domeny' }

    $sel1 = Resolve-M365TRDnsCname -Name "selector1._domainkey.$Domain"
    $sel2 = Resolve-M365TRDnsCname -Name "selector2._domainkey.$Domain"
    $dnsPart = if ($sel1 -and $sel2) { 'selector1 i selector2 opublikowane w DNS' }
               elseif ($sel1) { 'selector1 opublikowany w DNS; selector2 BRAK' }
               elseif ($sel2) { 'selector2 opublikowany w DNS; selector1 BRAK' }
               else { 'brak opublikowanych selektorow w DNS' }

    "$m365Part; $dnsPart"
}

function Get-Collector_Exchange_EmailAuthenticationDns {
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TREXOCommand -ScriptBlock { Get-AcceptedDomain }
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Uwierzytelnianie poczty (SPF / DKIM / DMARC)' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'Exchange' -Section 'Uwierzytelnianie poczty (SPF / DKIM / DMARC)' -Status 'empty' `
            -Description 'Weryfikacja publicznych rekordów DNS (SPF, DKIM, DMARC) dla domen pocztowych tenanta.'
    }

    $flat = $r.Data | ForEach-Object {
        $domainName = $_.DomainName
        [PSCustomObject]@{
            'Domena' = $domainName
            'SPF'    = Get-M365TRSpfSummary -Domain $domainName
            'DKIM'   = Get-M365TRDkimSummary -Context $Context -Domain $domainName
            'DMARC'  = Get-M365TRDmarcSummary -Domain $domainName
        }
    }
    New-M365TRCollectorResult -Component 'Exchange' -Section 'Uwierzytelnianie poczty (SPF / DKIM / DMARC)' `
        -Description 'Weryfikacja publicznych rekordów DNS (SPF, DKIM, DMARC) dla domen pocztowych tenanta - dane pobrane bezpośrednio z publicznego DNS, nie z konfiguracji M365.' `
        -Status 'ok' -Data $flat
}
