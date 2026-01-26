#!/bin/env bash

# Creates users from a CSV. On multisite, adds user to every site.
#
# CSV expects to have the following values with no header row as labels:
# username
# email
# role (a valid WP role)
# superadmin (1 or 0)

source 'source/includes.sh';

# Check if this is a multisite/network installation of WordPress.
is_multisite=$(wp_skip_all config get MULTISITE);

echo;

if [ "$is_multisite" == 1 ]; then
	echo 'Multisite detected';
	echo '   Users will be added to every network site';
else
	echo 'Multisite NOT detected';
fi

echo;

# Prompt the user for the path to a CSV with username and email.
read -r -p 'Path to CSV file with users [./user-create.csv]: ' csv_path;

# Set default value if empty string provided.
[[ -z "$csv_path" ]] && csv_path='./user-create.csv';

# Ensure the file actually exists.
if [[ ! -f "$csv_path" ]]; then

	echo "The file you provided does not exist: ${csv_path}";
	exit 1;

fi

######################################################
# Read the CSV and create the user(s)
######################################################

# Init the user counter.
user_count=0;

# Loop over the entire CSV file.
while IFS="," read -r username email role superadmin; do

	# Create the user. Only output WPCLI success message on successful creation.
	if new_user_id=$(wp_skip_all user create --porcelain "$username" "$email" --role="$role" >&1 ); then

		# Update the count for each successful user creation.
		((user_count++));

		echo "'$username' was successfully created.";

		# Check if the user should be a superadmin.
		if [[ "1" == "$superadmin" ]]; then

			wp_skip_all super-admin add $username;

		else

			for site_url in $(wp_skip_all site list --field="url" --archived=0 --deleted=0 --spam=0); do

				# The user is not a superadmin so add them to each site individually.
				wp_on_site user set-role "$new_user_id" "$role";

			done;

		fi

	else

		# Output any errors from WPCLI for the user creation.
		>&2

	fi

done < "$csv_path"

echo "Users added: ${user_count}";
