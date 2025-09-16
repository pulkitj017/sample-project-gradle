#!/bin/bash

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
    # Extract the dependency name, current version, and latest version
    match($0, /-\s([^[]+)\[([^\->]+)->([^\]]+)\]/, arr)
    dependency = arr[1]
    current_version = arr[2]
    latest_version = arr[3]
    # Print the formatted dependency information to the output file
    if (dependency != "" && current_version != "" && latest_version != "") {
        printf "%-65s %-20s %-20s\n", dependency, current_version, latest_version >> out
    }
}
' "$input_file"

# Notify the user
echo "Formatted report saved to $output_file"
