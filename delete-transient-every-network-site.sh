#!/bin/sh

# Loop through each network site and delete a transient.

# The transient to search for (can use wild cards *).
transient_search_term='*events_*';

echo;
for site_url in $(wp site list --allow-root --skip-themes --skip-plugins --deleted=0 --archived=0 --spam=0 --field=url); do

	found_transients=$(wp transient list --allow-root --skip-themes --skip-plugins --format=csv --fields=name --search=$transient_search_term --url=$site_url | awk 'NR>1 {print}'
);

	echo '################################################'
	echo $site_url;
	echo
	echo 'Deleting transients: ';

	# Check if it is NOT empty.
	if [[ -z $found_transients ]]; then
	    echo 'none';
	else
		echo $found_transients;
	fi

	echo;

	for transient in $found_transients; do

		wp transient delete --allow-root --skip-themes --skip-plugins --url=$site_url $transient;

	done;

done;
 
