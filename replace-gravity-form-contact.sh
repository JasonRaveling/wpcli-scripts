#!/bin/sh

# This script loops through each network site and replace an email contact with another for Gravity
# Forms notifications.

old_contacts=("some-person@somesite.com");
new_contact="different-person@anothersite.com";

# wp-cli with extra flags and targeting one site.
wp_on_site () {
	wp --skip-themes --allow-root --url="${site_url}" "$@"
}

# Loop over every network site.
for site_id in $(wp site list --allow-root --deleted=0 --archived=0 --spam=0 --field=site_id); do

	echo
	echo "Replacing Gravity Forms contact on site ID ${site_id}";

	# Loop $old_contacts.
	x=1;
	for old_contact in "${old_contacts[@]}"; do

		echo "${old_contact}  >>>  ${new_contact}";

		query="
UPDATE wp_${site_id}_gf_form_meta
SET
	notifications = REPLACE(
		notifications,
		'${old_contact}',
		'${new_contact}'
	)
WHERE
	notifications IS NOT NULL;";

		echo $query;

		wp db query "${query}" --allow-root --skip-themes --skip-plugins
	done;

	echo;

done;
