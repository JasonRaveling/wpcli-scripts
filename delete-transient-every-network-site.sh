#!/bin/env bash

# Loop through each network site and delete a transient.
#
# The transient to search for (can use wild cards *).
transient_search_term='*events_*';

source 'source/includes.sh';

echo;
for site_url in $(wp_skip_all site list --field=url); do

	found_transients=$(wp_skip_all transient list --format=csv --fields=name --search=$transient_search_term --url=$site_url | awk 'NR>1 {print}'
);

	echo '################################################'
	echo $site_url;
	echo
	echo 'Deleting transients: ';

	# Check if it is NOT empty.
	if [[ -z $found_transients ]]; then
	    echo '    none';
	else
		echo "    $found_transients";
	fi

	for transient in $found_transients; do

		wp transient delete --allow-root --skip-themes --skip-plugins --url=$site_url $transient;

	done;

done;
 
