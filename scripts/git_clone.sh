#!/bin/sh

set -o errexit
set -o nounset
set -o pipefail

# Check for a custom data location
if [ -z "${DATA_LOCATION+x}" ]; then
    DATA_LOCATION="/data"
fi

# Create data dir if it does not exist
if [ ! -d "$DATA_LOCATION" ]; then
    mkdir -p $DATA_LOCATION
    if [ $? -ne 0 ]; then
        printf "    - Failure - Could not create specified dir %s\n" "$DATA_LOCATION"
        exit 1
    else
        printf "    - Success - created dir %s\n" "$DATA_LOCATION"
    fi
else
    printf "    - Success - %s already exists\n" "$DATA_LOCATION"
fi

# Change into data location
cd $DATA_LOCATION

# Get individual repo's from input string
if [ ! -z "$REPO_STRING" ]; then
    IFS='; ' read -a repos <<<"$REPO_STRING"
    for repo in "${repos[@]}"; do
        repo_author="$(dirname $repo)"
        repo_name="$(basename $repo)"
        remote_url="git@github.com:$repo.git"

        if ! git clone "${remote_url}" 2>/dev/null && [ -d "$repo_name" ]; then
            printf "    - Success - \"%s\" already cloned into %s\n" "$repo" "$DATA_LOCATION/$repo_name"
        else
            printf "    - Success - Cloned repository \"%s\" into %s\n" "$repo" "$DATA_LOCATION/$repo_name"
        fi
    done
else
    printf "    - Failure - No git repositories passed to Docker instance\n"
    # exit 1
fi

# Set all of the files to rwx
chmod -R 647 $DATA_LOCATION

# Change back to root 
cd /
