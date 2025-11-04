#!/bin/env bash

# Loop through each network site and update a single meta key value pair.

# The meta key to update values for.
meta_key='_wp_page_template';

source 'source/includes.sh';

#
# The value pairs below will be searched and replaced.
#
old_value1='template-default-no-nav.php';
new_value1='template-default-no-nav-classic-editor.php';

old_value2='templateincludes-default.php';
new_value2='templateincludes-default-classic-editor.php';

echo;
for site_id in $(wp_skip_all site list --deleted=0 --archived=0 --spam=0 --field=blog_id); do
    echo "Replacing on site ID ${site_id}";
    echo "meta_key:   ${meta_key}";
    echo "meta_value: ${old_value1} -> ${new_value1}";
    echo "meta_value: ${old_value2} -> ${new_value2}";

    # The table name for postmeta on the current site in the loop.
    postmeta_table="wp_${site_id}_postmeta";

    query="
UPDATE ${postmeta_table} SET meta_value = '${new_value1}' WHERE meta_key = '${meta_key}' AND meta_value = '${old_value1}';
UPDATE ${postmeta_table} SET meta_value = '${new_value2}' WHERE meta_key = '${meta_key}' AND meta_value = '${old_value2}';
";

    wp_skip_all db query "${query}";

    echo "Done";
    echo;
    echo "====================================";
    echo;

done;

# Parent page options are stored as transients. Lets remove them to start fresh.
wp transient delete --allow-root --all --network
