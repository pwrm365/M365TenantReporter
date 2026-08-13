function Get-Collector_EntraID_SecureScore {
    param([Parameter(Mandatory)]$Context)
    $r = Invoke-M365TRGraphRequest -Context $Context -Path '/security/secureScores?$top=1'
    if (-not $r.Success) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Secure Score' -Status $r.Status -Message $r.Message
    }
    if ($r.Data.Count -eq 0) {
        return New-M365TRCollectorResult -Component 'EntraID' -Section 'Secure Score' -Status 'empty' `
            -Description 'Wynik Microsoft Secure Score oraz stan poszczególnych kontrolek zabezpieczeń.'
    }
    $score = $r.Data[0]
    $pct = if ($score.maxScore -gt 0) { [Math]::Round(($score.currentScore / $score.maxScore) * 100) } else { 0 }

    # Nazwy kontrolek w controlScores są wewnętrznymi identyfikatorami (np. "spo_idle_session_timeout") -
    # doczepiamy czytelny tytul z secureScoreControlProfiles, tam gdzie się da.
    $profilesResult = Invoke-M365TRGraphRequest -Context $Context -Path '/security/secureScoreControlProfiles'
    $profileById = @{}
    if ($profilesResult.Success) {
        foreach ($p in $profilesResult.Data) { $profileById[$p.id] = $p }
    }

    $summaryRow = [PSCustomObject]@{ 'Kontrolka' = 'WYNIK OGÓLNY'; 'Kategoria' = ''; 'Wynik' = "$($score.currentScore) / $($score.maxScore) ($pct%)" }
    $controlRows = foreach ($cs in (@($score.controlScores) | Sort-Object controlCategory, controlName)) {
        $profile = $profileById[$cs.controlName]
        $title = if ($profile -and $profile.title) { $profile.title } else { ConvertTo-M365TRHumanizedName ($cs.controlName -replace '_', ' ') }
        $maxScore = if ($profile) { $profile.maxScore } else { $null }
        $wynik = if ($maxScore) { "$($cs.score) / $maxScore" } else { "$($cs.score)" }
        [PSCustomObject]@{
            'Kontrolka' = $title
            'Kategoria' = $cs.controlCategory
            'Wynik'     = $wynik
        }
    }
    $flat = @($summaryRow) + @($controlRows)
    New-M365TRCollectorResult -Component 'EntraID' -Section 'Secure Score' `
        -Description 'Wynik Microsoft Secure Score oraz stan poszczególnych kontrolek zabezpieczeń - dane pobrane bezpośrednio z Microsoft, bez dodatkowej interpretacji.' `
        -Status 'ok' -Data $flat
}
