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
	[wp_path]='/data/domains/dev.bemidjistate.edu/public_html/'

);
