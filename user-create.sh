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
is_multisite=$(wp config get MULTISITE);

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
[[ ! -f "$csv_path" ]]; then

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

	# Create the user.
	new_user_id=$(wp_skip_all user create --porcelain "$username" "$email" --role="$role");

	# Check if the user should be a superadmin.
	if [[ "1" == "$superadmin" ]]; then

		wp super-admin add $username;

	fi

	# Update the count for each successful user creation.
	[[ new_user_id > 0 ]] && ((user_count++));

done < "$csv_path"

echo "Users added: ${user_count}";
