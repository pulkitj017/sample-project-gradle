# #!/bin/bash

# # Input file
# HTML_FILE="./build/reports/dependency-license/index.html"

# # Check if the file exists
# if [[ ! -f "$HTML_FILE" ]]; then
#   echo "Error: File '$HTML_FILE' not found!"
#   exit 1
# fi

# echo "Fetching licenses from $HTML_FILE..."
# echo ""

# # Extract and format license details
# awk '
#   BEGIN {
#     print "License Report:\n"
#     print "----------------------------------------"
#     printf "%-5s %-30s %-15s %-50s\n", "S.No", "Dependency", "Version", "License"
#     print "----------------------------------------"
#   }
#   /<strong>Group:/ {
#     group = $0
#     gsub(/.*<strong>Group:<\/strong> /, "", group)
#     gsub(/<.*/, "", group)
#   }
#   /<strong>Name:/ {
#     name = $0
#     gsub(/.*<strong>Name:<\/strong> /, "", name)
#     gsub(/<.*/, "", name)
#   }
#   /<strong>Version:/ {
#     version = $0
#     gsub(/.*<strong>Version:<\/strong> /, "", version)
#     gsub(/<.*/, "", version)
#   }
#   /<strong>POM License:/ {
#     license = $0
#     gsub(/.*<strong>POM License:/, "", license)
#     gsub(/<.*/, "", license)
#     printf "%-5s %-30s %-15s %-50s\n", ++count, group"."name, version, license
#   }
# ' "$HTML_FILE"

# echo "----------------------------------------"
# echo "Done! The licenses have been extracted."

#!/bin/bash

# Path to the HTML file
HTML_FILE="./build/reports/dependency-license/index.html"

# Output file for storing the report
OUTPUT_FILE="./license_report.txt"

# Check if the input HTML file exists
if [[ ! -f "$HTML_FILE" ]]; then
  echo "Error: File '$HTML_FILE' not found at '$HTML_FILE'!"
  exit 1
fi

# Start writing to the output file
echo "Generating license report in $OUTPUT_FILE..."
echo ""

# Write the header to the output file
echo "License Report:" > "$OUTPUT_FILE"
echo "----------------------------------------" >> "$OUTPUT_FILE"
printf "%-5s %-30s %-15s %-50s\n" "S.No" "Dependency" "Version" "License" >> "$OUTPUT_FILE"
echo "----------------------------------------" >> "$OUTPUT_FILE"

# Extract and write license details
awk '
  /<strong>Group:/ {
    group = $0
    gsub(/.*<strong>Group:<\/strong> /, "", group)
    gsub(/<.*/, "", group)
  }
  /<strong>Name:/ {
    name = $0
    gsub(/.*<strong>Name:<\/strong> /, "", name)
    gsub(/<.*/, "", name)
  }
  /<strong>Version:/ {
    version = $0
    gsub(/.*<strong>Version:<\/strong> /, "", version)
    gsub(/<.*/, "", version)
  }
  /<strong>POM License:/ {
    license = $0
    gsub(/.*<strong>POM License:/, "", license)
    gsub(/<.*/, "", license)
    printf "%-5s %-30s %-15s %-50s\n", ++count, group"."name, version, license >> "'"$OUTPUT_FILE"'"
  }
' "$HTML_FILE"

# Final message
echo "----------------------------------------" >> "$OUTPUT_FILE"
echo "Report generated successfully in $OUTPUT_FILE."
echo "Done! Check the output file for details."

