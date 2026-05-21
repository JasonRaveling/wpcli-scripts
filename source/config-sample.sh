# Rename this file to `config.sh` and modify as needed.

# Global configs for these scripts.
#
# No shebang needed as this is an include.
# shellcheck disable=SC2148

# Disable unused error since this file is included in other files.
# shellcheck disable=SC2034
declare -A config=(

	# The path to the root of your WordPress installation.
	#
	# This is set so that these scripts can live outside of the WordPress installation.
	[wp_path]='/var/www/public_html/'

	# Whether or not to allow root to run wpcli.
	#
	# By default wpcli will display an error and exit if you run it as root. Set this to 1 to enable
	# running wpcli as root.
	[allow_root]=0

);
