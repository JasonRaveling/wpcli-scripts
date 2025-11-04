#!/bin/env bash

# Loops through all network sites. If the current theme matches the specified name, a different
# theme is activated.

source 'source/includes.sh';

# Set the string of the theme names.
current_theme_name='Old Theme';
new_theme_name='New Theme';

# Set the output file, with a suffix of unix timestamp.
output_file="theme-changed-sites-log-$(date +'%s')";

# Empty/create the output file.
echo "###################################################################" > $output_file;
echo "Sites with theme updated from ${current_theme_name} to ${new_theme_name}" >> $output_file;
echo "###################################################################" >> $output_file;

# Network enable the new theme.
wp_skip_all theme enable $new_theme_name --network;

for site in $(wp_skip_all site list --archived=0 --deleted=0 --field=url); do

        echo "Site: $site";

        # Get the name of the currently active theme of the current network site.
        active_theme=$(wp_skip_all option get current_theme --url="${site}");

        # Check if the current site uses the specified theme and flag $uses_theme as such.
        [[ "$active_theme" =~ "$current_theme_name" ]] && uses_theme=true || uses_theme=false;

        # Do some actions when a matching theme was detected.
        if [ true = "$uses_theme" ]; then

                # Add the site URL to the log file.
                echo "$site" >> $output_file;
                echo $(wp_skip_all theme activate "$new_theme_name" --url="$site");

        fi

        # Just a separator for easier reading of output.
        echo '===============================================';

done;

echo;
wp_skip_all theme delete ${current_theme_name} --force;
wp_skip_all transient delete --all --network;
wp_skip_all transient delete --all;
