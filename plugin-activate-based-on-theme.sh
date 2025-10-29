#!/bin/sh

# Activates or deactivates a plugin based on the currently installed theme.

theme='some-theme';
plugin='a-plugin';

wp plugin deactivate --network $plugin;

# Get every network site.
for s in $(wp site list --field=url); do

	echo;

	# Run the command but we really want the return status: $?
	wp theme is-active $theme --url="$s";
	theme_is_not_active=$?;
	echo "Site: $s";

	if [[ 1 -eq $theme_is_not_active ]]; then
		echo "$theme is NOT active.";
		echo "Activating $plugin plugin...";
		wp plugin activate $plugin --url="$s";
	else
		echo "$theme is active. Skipping plugin activation.";
		echo "Deactivating $plugin plugin...";
		wp plugin deactivate $plugin --url="$s";
	fi;

done;
