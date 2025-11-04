# Overrides the default wp command for more readable scripts and more flexible modification of
# the scripts usage of the wp command.
#
# No shebang needed as this is an include.
# shellcheck disable=SC2148

# Usage of the wp command on the main site. Skips themes and plugins.
wp_skip_all () {
	wp --skip-themes --skip-plugins --path="${config[wp_path]}" "$@"
}


# Usage of the wp command for a specific site.
#
# It expects $site_url to be set. This is useful in a for loop of every site.
wp_on_site () {
	wp --skip-themes --skip-plugins --path="${config[wp_path]}" --url="${site_url}" "$@"
}
