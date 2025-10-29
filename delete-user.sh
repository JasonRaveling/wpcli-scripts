#!/bin/sh

# This interactive script deletes a given user by their ID and reattributes their content to another
# user based on the provided ID.

echo;
echo 'You are about to delete a user and attribute any content they may have to another use.';
echo;
echo 'You may exit any time with Ctrl+c';
echo;

# Prompt the user for the ID to DELETE.
while [[ -z "$user_id_delete" || "$user_id_delete" =~ re'^[0-9]+$' ]]; do
	read -p 'User ID to delete: ' user_id_delete;
done;

# Prompt for the attribution user.
while [[ -z "$user_id_attribute" || "$user_id_attribute" =~ re'^[0-9]+$' ]]; do
	read -p 'User ID to attribute content to: ' user_id_attribute;
done;

# Prompt for a site ID or no site ID to get all.
#
# In some cases we may just want to remove them from a single site instead of the entire network.
while [[ -z "$site_id" || "$site_id" =~ re'^[0-9]+$' ]]; do
	read -p 'Site ID to delete the user from (999 for every site) : ' site_id;
done;

# Prompt for the site ID to delete the user from.
if [[ 999 = $site_id ]]; then
	sites=$(wp --allow-root --skip-themes --skip-plugins site list --field="url" --archived=0);
	sites_name='All sites in the WP network';
else
	sites=$(wp --allow-root --skip-themes --skip-plugins site list --field="url" --site__in=${site_id});
	sites_name="$sites";
fi

echo;

# Add human readable info for the user to be deleted.
user_name_delete=$(wp --allow-root --skip-themes --skip-plugins user get ${user_id_delete} --field="display_name");
# user_login_delete=$(wp --allow-root --skip-themes --skip-plugins user get ${user_id_delete} --field="user_login");

# Add human readable info for the user to get attribution of content.
user_name_attribute=$(wp --allow-root --skip-themes --skip-plugins user get ${user_id_attribute} --field="display_name");
# user_login_attribute=$(wp --allow-root --skip-themes --skip-plugins user get ${user_id_attribute} --field="user_login");

# Confirm before moving on.
while [[ -z "$confirmed" ]]; do
	echo '* WARNING! *******************************************************************************';
	echo '******************************************************************************************';
	echo '* You are about delete a user!';
	echo '******************************************************************************************';
	echo;
	echo "User to delete:       ${user_id_delete} (${user_name_delete})";
	echo "Attribute content to: ${user_id_attribute} (${user_name_attribute})";
	echo "Site ID:              ${site_id} (${sites_name})";
	echo;
	read -p "Continue? [y/n]: " confirmed;
	echo;
done;

case $confirmed in
	n|N)
		echo;
		echo 'You have decided not to continue. No data will be changed. Bye.';
		exit;
	;;
esac

# Loop through every site individually. Using the --network flag in `wp user delete` will not let
# you reattribute content.
echo 'Removing the user...';
for site in $sites; do
	wp --allow-root --skip-themes --skip-plugins user delete $user_id_delete --reassign="${user_id_attribute}" --url="${site}" ;
done;
