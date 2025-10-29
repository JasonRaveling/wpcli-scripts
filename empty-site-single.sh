#!/bin/bash
#
# A script for emptying an individual network site and leaving an empty site.
#
# NOTE: Some PHP scripts may not like to be loaded via the command line. In some cases you can
# check if 'cli' === php_sapi_name() and return out of a function. If you see any PHP errors while
# running this script, you may want to start there.

# Script version
version='1.0.3';

# All or part of the directory your production environment runs in. This is checked as a regex. This
# will protect it from accidental deletion.
production_dir='www.';

# The theme name/slug to activate.
theme_to_use='my-theme-name';

echo "Running script to wipe a single network site. Version ${version}";
echo;

# The default page template file to use when creating the new home page.
default_page_template='template-default-nav-removed.php';

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

while [[ -z $site_id ]]; do
	read -p "Please provide the Site ID: " site_id;
done;

site_url="$(wp db query "SELECT option_value FROM wp_${site_id}_options WHERE option_name = 'siteurl'" --skip-themes --skip-plugins --allow-root --skip-column-names)";
site_url="${site_url}/";

if [[ -z $site_url ]]; then
	echo;
	echo "No site URL could be found for the site ID you provided: ${site_id}";
	echo;
	exit;
fi

echo
echo -e "\e[37;41m##############################################################\e[0m"
echo
echo -e "\e[37;41mWARNING!\e[0m"
echo
echo "You are about to run a destructive script on a single network site."
echo "This script removes all uploads, posts, comments, terms, site"
echo "options... everything. It leaves you with a completely blank site."
echo
echo "Working dir: ${current_dir}"
echo "Site ID:  ${site_id}"
echo "Site URL: ${site_url}"
echo
echo -e "\e[37;41m##############################################################\e[0m"
echo
read -r -p "Continue? [y/N] " user_consent
echo

# Pause before continuing to be sure the user understands this is destructive.
case $user_consent in
	[yY])
		echo "You have agreed to destroy the entire site. Continuing."
	;;
	*)
		echo "You have chosen not to continue. Exiting."
		exit;
	;;
esac


###################################################################################################
# Setup / Config for the rest of the script.
###################################################################################################


echo $SECONDS > /dev/null # start the timer
echo

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
# Destroy the individual site.
###################################################################################################

wp --allow-root maintenance-mode activate

echo "Destroying site ID: ${site_id}"

# wp-cli with extra flags and targetting one site.
wp_on_site () {
	wp --allow-root --url="${site_url}" "$@"
}

echo
echo 'Emptying the site.'

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

echo "The following site options were retained:";
echo "    ${site_options_to_retain}";

# Delete all transients that may exist. This should get picked up in deleting options but in some
# network instances transients are not stored as options.
wp_on_site transient delete --all

# Change the theme.
wp_on_site theme activate "$theme_to_use"

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
homepage_id=$(wp_on_site post create --post_type="page" --post_title="Landing Page ${blogname}" --post_status=publish --page_template="${default_page_template}" --post_content='This site is a blank slate. Start creating!' --post_author=1 --porcelain)
wp_on_site option update show_on_front 'page' # Tell WP to display a page as the home page.
wp_on_site option update page_on_front $homepage_id # Set the new page as the home page.

# Update URLs to https. Do this last since we are using the URL flag to update the site.
wp_on_site option update home "${site_url/http:/https:}"
wp_on_site option update siteurl "${site_url/http:/https:}"
wp_on_site rewrite structure '/%year%/%monthnum%/%day%/%postname%/'


###################################################################################################
# Final Cleanup
###################################################################################################

wp --allow-root maintenance-mode deactivate

# Run wp-cron now that all of these changes were made.
home_page_url=$(wp site list --allow-root --field="url" | head -n 1)
echo "Running wp-cron.php for the first time. (${home_page_url}wp-cron.php)"
curl -s "${home_page_url}wp-cron.php" -o /dev/null

echo;
echo "The script ran for $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"
echo "Completed: " $(date);
