# Overrides the default wp command for more readable scripts and more flexible modification of
# the scripts usage of the wp command.
#
# No shebang needed as this is an include.
# shellcheck disable=SC2148

# Usage of the wp command on the main site. Skips themes and plugins.
wp_skip_all () {

	# Setup the variable for building a wpcli command.
	local -a cmd=( wp )

	# Add the wpcli command to run and any additional flags that were used.
	cmd+=( "$@" )

	# Check if a path to a WP installation was provided. If none was provided, wpcli will default to
	# the current directory.
	if [[ -n "${config[wp_path]:-}" ]]; then
		cmd+=( --path="${config[wp_path]}" )
	fi

	# Check if allow root was set to 1 and add the flag.
	if (( config[allow_root] )); then
		cmd+=( --allow-root )
	fi

	# Add flags to use every time.
	cmd+=( '--skip-themes --skip-plugins' )

	# Run the command
	"${cmd[@]}"

}


# Usage of the wp command for a specific site.
#
# It expects $site_url to be set. This is useful in a for loop of every site.
wp_on_site () {

	# Setup the variable for building a wpcli command.
	local -a cmd=( wp )

	# Add the wpcli command to run and any additional flags that were used.
	cmd+=( "$@" )

	# Check if a path to a WP installation was provided. If none was provided, wpcli will default to
	# the current directory.
	if [[ -n "${config[wp_path]:-}" ]]; then
		cmd+=( --path="${config[wp_path]}" )
	fi

	# Check if allow root was set to 1 and add the flag.
	if (( config[allow_root] )); then
		cmd+=( --allow-root )
	fi

	# Add flags to use every time.
	cmd+=( --skip-themes --skip-plugins --url="${site_url}" )

	# Run the command
	"${cmd[@]}"

}
