#!/bin/bash

# Loops through all network sites. If the current theme matches the specified name, a different
# theme is activated.

# Set the string of the theme names.
current_theme_name='Old Theme';
new_theme_name='New Theme';

# Set the output file, with a suffix of unix timestamp.
output_file="theme-changed-sites-log-$(date +'%s')";

# Empty/create the output file.
echo '' > $output_file;

# Network enable the new theme.
wp theme enable $new_theme_name --network --allow-root --skip-themes --skip-plugins;

for site in $(wp site list --archived=0 --deleted=0 --field=url --allow-root --skip-themes --skip-plugins); do

        echo "Site: $site";

        # Get the name of the currently active theme of the current network site.
        active_theme=$(wp option get current_theme --allow-root --skip-plugins --skip-themes --allow-root --url="${site}");

        # Check if the current site uses the specified theme and flag $uses_theme as such.
        [[ "$active_theme" =~ "$current_theme_name" ]] && uses_theme=true || uses_theme=false;

        # Do some actions when a matching theme was detected.
        if [ true = "$uses_theme" ]; then

                # Add the site URL to the log file.
                echo "$site" >> $output_file;
                echo $(wp theme activate "$new_theme_name" --skip-themes --skip-plugins --url="$site");

        fi

        # Just a separator for easier reading of output.
        echo '===============================================';

done;

echo;
wp theme delete ${current_theme_name,,} --force --skip-plugins --skip-themes --allow-root;
wp transient delete --all --network --allow-root --skip-themes --skip-plugins;
wp transient delete --all --allow-root --skip-themes --skip-plugins;
