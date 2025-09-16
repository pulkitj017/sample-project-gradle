#!/bin/bash

INPUT_FILE="./build/reports/dependency-license/licenses.txt"
OUTPUT_FILE="./license_report.txt"

# Check if the input file exists
if [[ ! -f "$INPUT_FILE" ]]; then
  echo "Error: File '$INPUT_FILE' not found!"
  exit 1
fi

# Start writing to the output file
echo "Generating license report in $OUTPUT_FILE..."
echo ""

# Write the header to the output file
echo "License Report:" > "$OUTPUT_FILE"
echo "----------------------------------------" >> "$OUTPUT_FILE"
printf "%-5s %-40s %-15s %-50s\n" "S.No" "Dependency" "Version" "License" >> "$OUTPUT_FILE"
echo "----------------------------------------" >> "$OUTPUT_FILE"

# Parse licenses.txt and extract dependency, version, and license
awk '
  /^([0-9]+)\. Group:/ {
    split($0, parts, " ")
    count = parts[1]
    group = parts[3]
    name = parts[5]
    version = parts[7]
  }
  /^POM License:/ {
    license = substr($0, index($0,$3))
    printf "%-5s %-40s %-15s %-50s\n", count, group"."name, version, license >> "'"$OUTPUT_FILE"'"
  }
' "$INPUT_FILE"

# Final message
echo "----------------------------------------" >> "$OUTPUT_FILE"
echo "Report generated successfully in $OUTPUT_FILE."
