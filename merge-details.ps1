# Inputs (plain text reports)
$outdatedFile = "outdated_dependencies_report.txt"           
$licensesTxt  = "licenses.txt"                                
$outputFile   = "sbom-result.txt"

if (!(Test-Path $outdatedFile)) { throw "Missing $outdatedFile" }
if (!(Test-Path $licensesTxt))  { throw "Missing $licensesTxt" }

# -------- Parse licenses.txt (Group: X  Name: Y  Version: Z + POM License lines) --------
$licenses = @()
$current = $null

Get-Content -LiteralPath $licensesTxt | ForEach-Object {
    $line = $_

    $m = [regex]::Match($line, '^\s*\d+\.\s+Group:\s+(.*?)\s+Name:\s+(.*?)\s+Version:\s+([^\s]+)\s*$')
    if ($m.Success) {
        if ($current) { $licenses += $current }
        $group   = $m.Groups[1].Value.Trim()
        $name    = $m.Groups[2].Value.Trim()
        $version = $m.Groups[3].Value.Trim()
        $current = [PSCustomObject]@{
            Dependency = "${group}:${name}"
            Version    = $version
            Licenses   = New-Object System.Collections.Generic.List[string]
        }
        return
    }

    if (-not $current) { return }

    $lm = [regex]::Match($line, '^\s*POM License:\s*(.*?)\s*-\s*(\S.*)\s*$')
    if ($lm.Success) {
        $licName = $lm.Groups[1].Value.Trim()
        $licUrl  = $lm.Groups[2].Value.Trim()
        $null = $current.Licenses.Add("$licName - $licUrl")
        return
    }
}

if ($current) { $licenses += $current }
$licenses = $licenses | ForEach-Object { $_.Licenses = ($_.Licenses | Select-Object -Unique); $_ }

# Build license index: dep -> version -> [licenses]
$licenseIndex = @{}
foreach ($l in $licenses) {
    if (-not $licenseIndex.ContainsKey($l.Dependency)) { $licenseIndex[$l.Dependency] = @{} }
    $licenseIndex[$l.Dependency][$l.Version] = $l.Licenses
}

# -------- Parse outdated_dependencies_report.txt (TXT) --------
# We treat it as 3 columns: 1st token = Dependency, 2nd = Current, 3rd+ = Latest (can contain "->", RC text, etc.)
$outdated = @{}
Get-Content -LiteralPath $outdatedFile | ForEach-Object {
    $raw = $_
    $line = $raw.TrimEnd()
    if (-not $line) { return }
    if ($line -match '^\s*[-=]+$') { return }
    if ($line -match '^\s*(Outdated Dependencies Report|Dependency|----------)\b') { return }

    # Split on whitespace: first = dep, second = current, rest = latest
    $parts = $line -split '\s+'
    if ($parts.Count -lt 3) { return }

    $dep     = $parts[0]
    $current = $parts[1]
    $latest  = ($parts[2..($parts.Count-1)] -join ' ').Trim()

    # Keep everything, including Gradle and Gradle plugin rows, as requested
    if (-not $outdated.ContainsKey($dep)) {
        $outdated[$dep] = [PSCustomObject]@{
            Dependency     = $dep
            CurrentVersion = $current
            LatestVersion  = $latest
        }
    }
}

# -------- Merge: union of all dependencies from licenses + outdated --------
$allDeps = @()
$allDeps += $outdated.Keys
$allDeps += ($licenses | ForEach-Object { $_.Dependency })
$depKeys = $allDeps | Where-Object { $_ } | Sort-Object -Unique

$rows = foreach ($depKey in $depKeys) {
    $upd = $outdated[$depKey]
    $current = $null
    $latest  = $null
    if ($upd) {
        $current = $upd.CurrentVersion
        $latest  = $upd.LatestVersion
    } else {
        # not in outdated list (likely up-to-date) → pick a version from licenses
        if ($licenseIndex.ContainsKey($depKey)) {
            $current = ($licenseIndex[$depKey].Keys | Select-Object -First 1)
        }
    }

    # License resolution: prefer exact (dep, current), else any for dep
    $licList = @()
    if ($licenseIndex.ContainsKey($depKey)) {
        if ($current -and $licenseIndex[$depKey].ContainsKey($current)) {
            $licList = $licenseIndex[$depKey][$current]
        } else {
            $firstVer = $licenseIndex[$depKey].Keys | Select-Object -First 1
            if ($firstVer) { $licList = $licenseIndex[$depKey][$firstVer] }
        }
    }

    [PSCustomObject]@{
        Dependency     = $depKey
        CurrentVersion = if ($current) { $current } else { "N/A" }
        LatestVersion  = if ($latest)  { $latest }  else { "N/A" }
        License        = if ($licList -and $licList.Count -gt 0) { ($licList -join ' | ') } else { 'N/A' }
    }
}

# -------- Output table --------
$col1 = 70
$header  = "Dependency".PadRight($col1) + "CurrentVersion".PadRight(20) + "LatestVersion".PadRight(20) + "License"
$divider = "-" * ($col1 + 20 + 20 + 7)
$lines   = @($header, $divider)
foreach ($r in $rows) {
    $lines += $r.Dependency.PadRight($col1) + $r.CurrentVersion.PadRight(20) + $r.LatestVersion.PadRight(20) + $r.License
}
$lines | Out-File -FilePath $outputFile -Encoding UTF8

$rows | Format-Table -Property Dependency, CurrentVersion, LatestVersion, License -AutoSize
Write-Host "Merged report written to $outputFile"
