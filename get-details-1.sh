#!/bin/bash
./gradlew build || echo "Gradle build failed or skipped"
./gradlew dependencies --write-locks || echo "Gradle lock generation skipped"
bash ./gradlew dependencyUpdates > outdated.txt
bash ./gradlew generateLicenseReport
# Input and output files
input_file="outdated.txt"
output_file="outdated_dependencies_report.txt"

# Initialize the output file with headers
{
    echo "Outdated Dependencies Report"
    echo
    printf "%-65s %-20s %-20s\n" "Dependency" "Current Version" "Latest Version"
    printf "%-65s %-20s %-20s\n" "----------" "---------------" "--------------"
} > "$output_file"

# Parse the input file for outdated dependencies
awk -v out="$output_file" '
/The following dependencies have later milestone versions:/ {found=1; next}
found && $0 ~ /^\s*-\s/ {
    # Extract using regex
    match($0, /-\s([^[]+)\[([^\->]+)->([^\]]+)\]/, arr)
    dependency = trim(arr[1])
    current_version = trim(arr[2])
    latest_version = trim(arr[3])

    if (dependency != "" && current_version != "" && latest_version != "") {
        printf "%-65s %-20s %-20s\n", dependency, current_version, latest_version >> out
    }
}
function trim(str) {
    sub(/^[ \t\r\n]+/, "", str)
    sub(/[ \t\r\n]+$/, "", str)
    return str
}
' "$input_file"

# Notify the user
echo "Formatted report saved to $output_file"
