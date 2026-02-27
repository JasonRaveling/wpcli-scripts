#!/bin/env bash

# Search the media library post title on every network site. Return as
# a CSV.

source 'source/includes.sh';

# The text to search for in the title.
search_regex=''; # Leave empty to return all.

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

	# Search for multi term phrases. Cases sensitive.
	wp_skip_all db query --skip-column-names "SELECT ${fields} FROM wp_${site_id}_posts WHERE post_type = 'attachment' AND post_REGEXP '${search_regex}';" >> $output_file;

	# The SQL query for searching the media library of a network site.
	sql_query="SELECT
		$site_id as site_id,
	    p.ID,
    	p.post_title,
    	p.post_mime_type,
    	pm1.meta_value AS file_path,
    	p.guid AS URL
	FROM
		wp_${site_id}_posts p
	LEFT JOIN
		wp_3_postmeta pm1 ON (p.ID = pm1.post_id AND pm1.meta_key = '_wp_attached_file')
	WHERE
		p.post_type = 'attachment'"

	# Check if a search string was provided.
	if [ -n "$search_regex" ]; then
		QUERY="$QUERY AND p.post_title REGEXP '${search_regex}'"
	fi

	wp_skip_all db query --skip-column-names "SELECT ${fields} FROM wp_${site_id}_posts WHERE post_type = 'attachment' AND post_REGEXP '${search_regex}';" tee -a $output_file;

done;

echo "Finished search. Results are in ${output_file}";
echo;
