#!/bin/sh

# Set the exact slug of the plugin you want to check
plugin_slug='classic-editor';

source 'source/wp-cli-override.sh';

# Requires 'bc' for floating-point percentage calculation
if ! command -v bc &> /dev/null; then
    echo "Error: 'bc' (basic calculator) is not installed."
    echo "Please install 'bc' to run this script."
    exit 1
fi

# Initialize counters
active_count=0
failed_sites=0

# Get all site URLs into a bash array (ignores 'Loading...' line)
mapfile -t sites < <(wp_skip_all site list --field=url --quiet)

# Get total site count
total_sites=${#sites[@]}

if [[ $total_sites -eq 0 ]]; then
    echo "No sites found."
    exit 0
fi

echo "Auditing '$plugin_slug' plugin status across $total_sites sites..."
echo "---"

# Loop through each site and check plugin status.
for s in "${sites[@]}"; do

    # Check if the plugin is active. Suppress errors for archived/deleted sites.
    # Exits with 0 if active, 1 if inactive/not-installed.
    wp_skip_all plugin is-active "$plugin_slug" --url="$s" >/dev/null 2>&1
    plugin_status=$?

    if [[ $plugin_status -eq 0 ]]; then
        # Status 0: Plugin is ACTIVE
        ((active_count++))
        echo "Site: $s | ACTIVE"
    elif [[ $plugin_status -eq 1 ]]; then
        # Status 1: Plugin is INACTIVE or not installed
        echo "Site: $s | INACTIVE"
    else
        # Any other status: WP-CLI command failed
        echo "Site: $s | FAILED to get status (site may be archived or deleted)"
        ((failed_sites++))
    fi
done

# Calculate results. Base percentages only on sites we could successfully check.
total_checked=$((total_sites - failed_sites))
inactive_count=$((total_checked - active_count))

if [[ $total_checked -gt 0 ]]; then
    # Use 'bc' for floating-point percentage calculation
    active_perc=$(echo "scale=2; ($active_count / $total_checked) * 100" | bc)
    inactive_perc=$(echo "scale=2; ($inactive_count / $total_checked) * 100" | bc)
else
    active_perc="0.00"
    inactive_perc="0.00"
fi

echo
echo "##################################################"
echo " Plugin Usage Report for: $plugin_slug"
echo "##################################################"

# Print the report
printf "Active:     %-5s sites (%s%%)\n" "$active_count" "$active_perc"
printf "Inactive:   %-5s sites (%s%%)\n" "$inactive_count" "$inactive_perc"
echo "---"
printf "Total Sites Checked:  %s\n" "$total_checked"
if [[ $failed_sites -gt 0 ]]; then
    printf "Sites Failed (skipped): %s\n" "$failed_sites"
fi
