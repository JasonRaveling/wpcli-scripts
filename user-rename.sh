#!/bin/env bash

# Renames user(s) to any given string.
#
# Use caution! The new name can be a non-standard WP username, with any characters.

source 'source/includes.sh';

# Prompt the user for the path to a CSV with username and email.
read -r -p 'Path to CSV file with users [./user-rename.csv]: ' csv_path;

# Set default value if empty string provided.
[[ -z "$csv_path" ]] && csv_path='./user-rename.csv';

# Ensure the file actually exists.
if [[ ! -f "$csv_path" ]]; then

	echo "The file you provided does not exist: ${csv_path}";
	exit 1;

fi

######################################################
# Read the CSV and update the user(s)
######################################################

# Init the user counter.
user_count=0;

# Loop over the entire CSV file.
while IFS="," read -r old_username new_username; do

	echo "Changing username: ${old_username}";

	# Ensure the user exists by getting the user ID.
	if user_id=$(wp_skip_all user get "${old_username}" --field=ID >&1 ); then

		# Set the SQL query for updating the current user's username and nicename.
		user_update_query="UPDATE wp_users SET user_login = '${new_username}', user_nicename = '${new_username}' WHERE ID = '${user_id}'";

		# Update the username and check the status of the change.
		if $(wp_skip_all db query "$user_update_query" >&1 ); then

			# Update the count for each successful user creation.
			((user_count++));

			echo "Changed to: ${new_username}";

		else

			# Output any errors from WPCLI from the query.
			>&2

		fi

	else

		# Output any WPCLI error related to checking if the user exists.
		>&2;

	fi

done < "$csv_path"

echo "Users updated: ${user_count}";
