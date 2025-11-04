#!/bin/env bash

# Activates or deactivates a plugin based on the currently activated theme.

source 'source/includes.sh';

# The plugin slug to activate.
plugin='classic-editor';

# The theme to check for when activating the plugin.
theme='some-theme';

wp_skip_all plugin deactivate --network $plugin;

# Get every network site.
for s in $(wp_skip_all site list --field=url); do

	echo;

	# Run the command but we really want the return status: $?
	wp_skip_all theme is-active $theme --url="$s";
	theme_is_not_active=$?;
	echo "Site: $s";

	if [[ 1 -eq $theme_is_not_active ]]; then
		echo "$theme is NOT active.";
		echo "Activating $plugin plugin...";
		wp_skip_all plugin activate $plugin --url="$s";
	else
		echo "$theme is active. Skipping plugin activation.";
		echo "Deactivating $plugin plugin...";
		wp_skip_all plugin deactivate $plugin --url="$s";
	fi;

done;
