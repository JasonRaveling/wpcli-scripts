#!/bin/bash

# A script for emptying each network site and leaving just the network structure.
#
# DO NOT RUN THIS AS ROOT since some commands could potentially delete unwanted data if run as root.

# Script version
version='1.0.3';

# All or part of the directory your production environment runs in. This is checked as a regex. This
# will protect it from accidental deletion.
production_dir='www';

# The theme name/slug to activate.
theme_to_use='my-theme-name';

# Gravity forms license key. Leave empty if you do not use it.
gf_license_key=""

# This is destructive so do not run it in production.
current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &>/dev/null && pwd )" # Get the directory that the script is being run in.
if [[ $current_dir =~ "$production_dir" ]]; then
	echo
	echo -e "\e[37;41mThe script is exiting. You cannot run this script in production.\e[0m"
	echo
fi

# Make sure that WP-CLI is installed.
if [[ "$(which wp 2>/dev/null)" == "" ]]; then
	echo
	echo "The WP-CLI command line interface could not be found. It is required for this script to run."
	echo
	echo "Visit https://wp-cli.org/ to get WP-CLI."
	echo
	exit
fi

echo
echo -e "\e[37;41m##############################################################\e[0m"
echo
echo -e "\e[37;41mWARNING!\e[0m"
echo
echo "You are about to run a destructive script on this entire site."
echo "This script removes all uploads, posts, comments, terms, site"
echo "options... everything. It leaves you with a completely blank site."
echo
echo "Working in: ${current_dir}"
echo "Version: ${version}"
echo
echo -e "\e[37;41m##############################################################\e[0m"
echo
read -r -p "Continue? [y/N] " user_consent
echo

# Pause before continuing to be sure the user understands this is desructive.
case $user_consent in
	[yY])
		echo "You have agreed to destroy the entire site. Continuing."
	;;
	*)
		echo "You have chosen not to contiune. Exiting."
		exit;
	;;
esac


###################################################################################################
# Setup / Config for the rest of the script.
###################################################################################################


echo $SECONDS > /dev/null # start the timer
echo
wp maintenance-mode activate

# Site options to retain when wiping a site.
site_options_to_retain=(
	"siteurl"
	"home"
	"blogname"
	"blogdescription"
	"admin_email"
);

# Build the string of --exclude args for `wp option list`
site_options_exclude_regex=$(printf "^%s$|" "${site_options_to_retain[@]}")
site_options_exclude_regex=${site_options_exclude_regex::-1} # remove the last pipe


###################################################################################################
# Destroy on a network level.
###################################################################################################
echo
echo "Starting sitewide destruction..."
echo

###################################################################################################
# Destroy individual sites.
###################################################################################################

echo "Destroying and removing archived and deleted sites."

delete_site() {

	site_id=$(wp site list | awk -v site_url=$site_url '{ if( $2 == site_url ) print $1; }')

	echo "Wiping site ID: ${site_id}"

	wp site delete --yes --skip-themes $site_id
}

for site_url in $(wp site list --deleted=1 --field=url); do
	echo "DELETED site found: ${site_url}"
	delete_site;
done;

for site_url in $(wp site list --archived=1 --field=url); do
	echo "ARCHIVED site found: ${site_url}"
	delete_site;
done;

for site_url in $(wp site list --spam=1 --field=url); do
	echo "SPAM site found: ${site_url}"
	delete_site;
done;


# wp-cli with extra flags and targetting one site.
wp_on_site () {
	wp --skip-themes --url="${site_url}" "$@"
}

echo
echo 'Emptying active sites.'
for site_url in $(wp site list --deleted=0 --archived=0 --spam=0 --field=url); do

	# Get the site nice name.
	blogname=$(wp_on_site option get blogname)

	echo
	echo "Destroying \"${blogname}\" at ${site_url}"

	# Empty the site leaving only users and site options in tact.
	wp_on_site site empty --uploads --yes 2>/dev/null

	# Delete all upload files. Only posts are removed when emptying a site. The files still exist.
	rm -rf "${current_dir}/wp-content/uploads/sites/${site_id}" 2>/dev/null

	# Delete site options minus some exclusions.
	options_to_delete=''
	for option_name in $(wp_on_site option list --field=option_name); do

		# Skip excluded option names. There is an --exclude flag for the options list but not for
		# multiple option names.
		if [[ $option_name =~ $site_options_exclude_regex ]]; then
			echo -e "\e[1;32mSkipping deletion:\e[0m ${option_name}"
			continue
		else
			options_to_delete="$option_name ${options_to_delete}"
		fi

	done;

	wp_on_site option delete $options_to_delete

	# Change the theme
	wp_on_site theme activate "${theme_to_use}"

	# Update options in case they are not already set as we want them.
	wp_on_site option update default_comment_status 'closed'
	wp_on_site option update default_ping_status 'closed'
	wp_on_site option update use_trackback '0'
	wp_on_site option update users_can_register '0'
	wp_on_site option update use_smilies '0'
	wp_on_site option update date_format 'F j, Y'
	wp_on_site option update time_format 'g:i a'
	wp_on_site option update links_updated_date_format 'F j, Y g:i a'
	wp_on_site option update timezone_string 'America/Chicago'
	wp_on_site core update-db # we have to do this per site so options get properly populated.

	# For some reason every user gets added to every site. If they do not actually belong, they get
	# the default user role of subscriber. Remove all who do not belong on the site.
	wp_on_site user delete --yes --reassign=1 $(wp_on_site user list --role='subscriber' --format='ids')

	# Create the home page of the network site.
	echo 'Creating the default landing page'
	homepage_id=$(wp_on_site post create --post_type="page" --post_title="Landing Page ${blogname}" --post_status=publish --page_template="template-landing-block.php" --post_content='This is the new home page. It will need some setting up.' --post_author=1 --porcelain)
	wp_on_site option update show_on_front "page" # Tell WP to display a page as the home page.
	wp_on_site option update page_on_front $homepage_id # Set the new page as the home page.

	# Update URLs to https. Do this last since we are using the URL flag to update the site.
	wp_on_site option update home "${site_url/http:/https:}"
	wp_on_site option update siteurl "${site_url/http:/https:}"
	wp_on_site rewrite structure '/%year%/%monthnum%/%day%/%postname%/'

done;


###################################################################################################
# Final Cleanup
###################################################################################################

# Delete all upload files. The posts are removed but files still exist.
rm -rf "${current_dir}/wp-content/uploads/*" 2>/dev/null

# Delete all transients, individual sites and network. Individual site transients should get picked
# up in deleting options but in some instances transients are not stored as options.
wp_on_site transient delete --all

# Disable caching
wp update option wp_cache_enabled "0"

# For some reason network meta also gets changed. ms_files_rewrite
# should be set to 0 otherwise WP reverts back to uploads file
# structure from WP versions pre-3.5.
wp network meta set 1 ms_files_rewriting 0

wp network meta set 1 subdomain_install 0 # We are using sub dirs
wp network meta set 1 global_terms_enabled 0

# wp_rg_* are deprecated tables https://docs.gravityforms.com/deprecated-database-tables/
for table in $(wp db tables wp_gf_* wp_*_gf_* wp_rg_* wp_*_rg_* --all-tables); do
	# Create a comma separated list of tables to be dropped for a MySQL qeury
	tables_to_remove_sql="${tables_to_remove_sql}, ${table}"
done;

tables_to_remove_sql=${tables_to_remove_sql:2} # remove the first two chars (, )

# Install and activate Gravity Forms.
wp plugin deactivate gravityforms --network
wp plugin uninstall gravityforms
echo "Deleting tables created by Gravity Forms."
wp db query "DROP TABLE IF EXISTS ${tables_to_remove_sql}"
wp maintenance-mode deactivate

# Check if a Gravity Forms license key was provided.
if [[ -n "$gf_license_key" ]]; then
	wp plugin install gravityforms
	wp plugin install gravityformscli --activate-network || echo -e "\e[1;31mFailed to install Gravity Forms CLI.\e[0m"
	wp gf install --skip-themes --key="${gf_license_key}" --activate-network
	wp gf setup --skip-themes --force
fi

home_page_url=$(wp site list --field="url" | head -n 1)
echo "Running wp-cron.php for the first time. (${home_page_url}wp-cron.php)"
curl -s "${home_page_url}wp-cron.php" -o /dev/null

echo "The script ran for $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"
echo "Completed: " $(date)
