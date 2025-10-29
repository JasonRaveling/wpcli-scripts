#!/bin/bash

# Loops through all sites. If the specified theme is enabled then it gets added to a list.

# Set the string of the
theme_name='My Cool Theme Name';

# Set the output file.
output_file='theme-activated-log.txt';

# Empty/create the output file.
echo '' > $output_file;

for site in $(wp site list --archived=0 --deleted=0 --field=url --allow-root); do

        # Get the WP option current_theme for comparison
        active_theme=$(wp option get current_theme --allow-root --url="${site}");

        [[ "$active_theme" =~ "$theme_name" ]] && uses_theme=true || uses_theme=false;

        if [ true = "$uses_theme" ]; then
                echo 'Adding following site to an output file.';
                echo $site >> $output_file;
        fi

        echo $site;
        echo "Uses theme: ${active_theme}";
        echo "Matched: ${uses_theme}";
        echo '===============================================';

done;
