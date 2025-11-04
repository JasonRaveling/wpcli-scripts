#!/bin/env bash

# Loops through all sites. If the specified theme is enabled then it gets added to a list.

source 'source/includes.sh';

# Set the string of the theme to look for. Case sensitive!
theme_name='A Cool Theme';

# Set the output file.
output_file='theme-activated-log.txt';

# Empty/create the output file.
echo "#############################################" > $output_file;
echo "Sites using the ${theme_name} theme" >> $output_file;
echo "#############################################" >> $output_file;

for site in $(wp_skip_all site list --archived=0 --deleted=0 --spam=0 --field=url); do

        # Get the WP option current_theme for comparison
        active_theme=$(wp_skip_all option get current_theme --url="${site}");

        # Using quotes since the var is a config above that accepts regex.
        # shellcheck disable=SC2076
        [[ "$active_theme" =~ "$theme_name" ]] && uses_theme=true || uses_theme=false;

        if [ true = "$uses_theme" ]; then
                echo 'Adding following site to an output file.';
                echo "$site" >> $output_file;
        fi

        echo "$site";
        echo "Uses theme: ${active_theme}";
        echo "Matched: ${uses_theme}";
        echo '===============================================';

done;


