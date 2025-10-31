#!/bin/sh

# This script audits all sites in a WordPress Multisite network and provides a count and percentage
# for every active theme.

source 'source/wp-cli-override.sh';

# Requires 'bc' for floating-point percentage calculation.
if ! command -v bc &> /dev/null; then
    echo "Error: 'bc' (basic calculator) is not installed."
    echo "Please install 'bc' to run this script."
    exit 1
fi

# Declare an associative array to hold theme counts
declare -A theme_counts

# Get all site URLs into a bash array (ignores 'Loading...' line)
mapfile -t sites < <(wp_skip_all site list --field=url --deleted=0 --archived=0 --quiet)

# Get total site count
total_sites=${#sites[@]}
failed_sites=0

if [[ $total_sites -eq 0 ]]; then
    echo "No sites found."
    exit 0
fi

echo "Auditing $total_sites sites..."
echo "---"

# Loop through each site and get its active theme
for s in "${sites[@]}"; do
    # Get the slug of the active theme.
    # '2>/dev/null' suppresses errors from archived/deleted sites.
    active_theme=$(wp_skip_all theme list --status=active --field=name --url="$s" 2>/dev/null)

    # Check if the command was successful and returned a theme name
    if [[ -n "$active_theme" ]]; then
        # Increment the count for this theme in the array
        ((theme_counts[$active_theme]++))
        echo "Site: $s | Theme: $active_theme"
    else
        echo "Site: $s | FAILED to get theme (site may be archived or deleted)"
        ((failed_sites++))
    fi
done

echo
echo "########################################"
echo " Theme Usage Report"
echo "########################################"

# Loop through the counted themes and print the report

# Get all unique theme names (the array keys) and sort them
sorted_themes=($(printf "%s\n" "${!theme_counts[@]}" | sort))

for theme in "${sorted_themes[@]}"; do
    count=${theme_counts[$theme]}

    # Use 'bc' for floating-point percentage calculation
    percentage=$(echo "scale=2; ($count / $total_sites) * 100" | bc)

    # Use 'printf' for clean, aligned columns
    printf "Theme: %-30s | Count: %-5s | Percentage: %s%%\n" "$theme" "$count" "$percentage"
done

echo "---"
printf "Total Sites Checked: %-5s\n" "$total_sites"
if [[ $failed_sites -gt 0 ]]; then
    printf "Sites Failed: %-5s (not included in percentage)\n" "$failed_sites"
fi
