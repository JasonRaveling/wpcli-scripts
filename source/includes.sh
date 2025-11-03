# This file is source'd / included with every script.

# The path to this file.
# path_to_this_file=$(realpath "${BASH_SOURCE[0]}");
directory_path=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

source "$directory_path/configs.sh";
source "$directory_path/wp-cli-overrides.sh";

echo '########################################################################';
echo "Working with the site at ${config[wp_path]}";
echo '########################################################################';
