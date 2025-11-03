#!/bin/sh

# This script loops through each network site and replace an email contact with another for Gravity
# Forms notifications.

source 'source/includes.sh';

old_contacts=("some-person@somesite.com");
new_contact="different-person@anothersite.com";

# Loop over every network site.
for site_id in $(wp_skip_all site list --deleted=0 --archived=0 --spam=0 --field=site_id); do

	echo
	echo "Replacing Gravity Forms contact on site ID: ${site_id}";

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

		wp_skip_all db query "${query}"
	done;

	echo;

done;
