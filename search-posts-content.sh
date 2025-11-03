#!/bin/bash

# Search post content for every post on every network site. Return as 
# a CSV with ID, post_title, and url.

# The text to search for.
search_regex='find this in content';

# A comma separated list of fields to return.
fields='ID,post_title,guid';

# The file to save results to.
output_file='search-results.txt';

# Reset the output file contents.
echo '' > $output_file;

echo;
echo 'Beginning search...';

# Get every network site.
all_site_ids=$(wp_skip_all site list --field="blog_id");

# Loop over every network site.
for site_id in $all_site_ids; do

	if [[ 1 -eq $site_id ]]; then
		continue;
	fi

	echo >> $output_file;
	echo "Results for Site ID ${site_id}" >> $output_file;

	# Using WP built in search. But "My favorite book" would turn up pages with "my" or "favorite" or "book".
	#wp_skip_all post list --post_type='page' --search="${term}" --fields="${fields}" --format=csv --url="${site}" | awk 'NR>1' >> $output_file;

	# Search for multi term phrases. Cases sensitive.
	wp_skip_all db query --skip-column-names "SELECT ${fields} FROM wp_${site_id}_posts WHERE post_content REGEXP '${search_regex}' AND post_status='publish';" >> $output_file;

done;

echo "Finished search. Results are in ${output_file}";
echo;
