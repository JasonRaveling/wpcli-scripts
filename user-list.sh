#!/bin/env bash

# Lists every user and their roles on every site.

source 'source/includes.sh';

fields_to_display='user_login,user_email,roles';

log_file='user-list.txt';

echo '#########################################################' | tee "$log_file";
echo 'Users by WordPress site' | tee -a "$log_file";
echo '#########################################################' | tee -a "$log_file";

for site_url in $(wp_skip_all site list --field="url" --archived=0 --deleted=0 --spam=0); do

	echo '-------------------------------------------------' | tee -a "$log_file";
	echo "Site ${site_url}" | tee -a "$log_file";
	wp_on_site user list --fields="${fields_to_display}" | tee -a "$log_file";

done;
