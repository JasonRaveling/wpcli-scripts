# This file is source'd / included with every script.
#
# No shebang needed as this is an include.
# shellcheck disable=SC2148

# The path to this file.
# path_to_this_file=$(realpath "${BASH_SOURCE[0]}");
directory_path=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

source "${directory_path}/config.sh";
source "${directory_path}/wp-cli-overrides.sh";

# Make sure that WP-CLI is installed.
if [[ "$(which wp 2>/dev/null)" == "" ]]; then
	echo
	echo "The WP-CLI command line interface could not be found. It is required for this script to run."
	echo
	echo "Visit https://wp-cli.org/ to get WP-CLI."
	echo
	exit 1; # Exit as a fail.
fi

echo '########################################################################';
echo "Working with the site at ${config[wp_path]}";
echo '########################################################################';
