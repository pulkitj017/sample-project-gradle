# Define the file paths
$outdatedFile = "outdated_dependencies_report.txt"
$licenseFile = "license_report.txt"
$outputFile = "sbom-result.txt"

# Read the outdated dependencies and licenses files
$outdatedDependencies = Get-Content $outdatedFile | Select-String -Pattern '(\S+):(\S+)\s+(\S+)\s+(\S+)' | ForEach-Object {
    $matches = $_.Matches
    if ($matches.Count -gt 0) {
        [PSCustomObject]@{
            Dependency    = $matches.Groups[1].Value
            CurrentVersion = $matches.Groups[3].Value
            LatestVersion  = $matches.Groups[4].Value
        }
    }
}

# Read the licenses file
$licenses = Get-Content $licenseFile | Select-String -Pattern '(\d+)\s+(\S+)\s+(\S+)\s+(.+)' | ForEach-Object {
    $matches = $_.Matches
    if ($matches.Count -gt 0) {
        [PSCustomObject]@{
            SNo        = $matches.Groups[1].Value
            Dependency = $matches.Groups[2].Value
            Version    = $matches.Groups[3].Value
            License    = $matches.Groups[4].Value
        }
    }
}

# Merge the data: matching dependencies, add new ones if no match
$mergedData = @()

# Add outdated dependencies to merged data, matching licenses when possible
foreach ($dep in $outdatedDependencies) {
    # Attempt to find a matching license
    $license = $licenses | Where-Object { $_.Dependency -ieq $dep.Dependency }
    if ($license) {
        # If matching dependency found, merge, use the license version for CurrentVersion
        $mergedData += [PSCustomObject]@{
            Dependency    = $dep.Dependency
            CurrentVersion = $license.Version  # Align with License Version
            LatestVersion  = $dep.LatestVersion
            License       = $license.License
        }
    } else {
        # If no match, add the dependency with N/A for License
        $mergedData += [PSCustomObject]@{
            Dependency    = $dep.Dependency
            CurrentVersion = $dep.CurrentVersion
            LatestVersion  = $dep.LatestVersion
            License       = "N/A"
        }
    }
}

# Add any dependencies from the license file that are not in the outdated list
foreach ($license in $licenses) {
    if ($outdatedDependencies | Where-Object { $_.Dependency -ieq $license.Dependency }) {
        continue  # Skip if already added
    }
    # Add new license entries without version info (use N/A for version fields)
    $mergedData += [PSCustomObject]@{
        Dependency    = $license.Dependency
        CurrentVersion = $license.Version  # Align with License Version
        LatestVersion  = "N/A"
        License       = $license.License
    }
}

# Manually format the output to a tabular format
$formattedOutput = "Dependency".PadRight(40) + "CurrentVersion".PadRight(20) + "LatestVersion".PadRight(20) + "License" + "`n"
$formattedOutput += "-" * 100 + "`n"

foreach ($item in $mergedData) {
    $formattedOutput += $item.Dependency.PadRight(40) + $item.CurrentVersion.PadRight(20) + $item.LatestVersion.PadRight(20) + $item.License + "`n"
}

# Write the formatted output to the file
$formattedOutput | Out-File -FilePath $outputFile

# Print the merged data to terminal as well in tabular format
$mergedData | Format-Table -Property Dependency, CurrentVersion, LatestVersion, License -AutoSize

Write-Host "Merge completed. Check the output file at $outputFile."
