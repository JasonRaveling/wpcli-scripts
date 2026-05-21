#!/bin/env bash

# Lists every user and their roles on every site.

source 'source/includes.sh';

fields_to_display='user_login,user_email,roles';

output_file='user-list.txt';

echo '#########################################################' | tee "$output_file";
echo 'Users by WordPress site' | tee -a "$output_file";
echo '#########################################################' | tee -a "$output_file";

for site_url in $(wp_skip_all site list --field="url" --archived=0 --deleted=0 --spam=0); do

	echo '-------------------------------------------------' | tee -a "$output_file";
	echo "Site ${site_url}" | tee -a "$output_file";
	wp_on_site user list --format=csv --fields="${fields_to_display}" | tee -a "$output_file";

done;
