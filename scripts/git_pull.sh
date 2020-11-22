#!/bin/sh

# Walk each of the directories in the data folder
for folder in $DATA_LOCATION/*; do
    # Change into dir if git repo exists
    cd $folder

    # Check for a git repo in dir
    if [ -d .git ]; then
        # Get the remote url if it exists
        remote_urls=$(git remote -v)
        if [ ! -z remote_url ]; then
            # Get update from remote
            git remote update &>/dev/null
            if [ ! $? -eq 0 ]; then
                printf "Failure - Unable to update from remote\n"
                continue
            fi

            # If repo is behind pull in latest
            # if [ $(git status -uno | grep behind | wc -l) -gt 0 ] && [ ! "$(git status -uno | grep ahead | wc -l)" -eq 0 ]; then
            if [ $(git status -uno | grep behind | wc -l) -gt 0 ]; then
                # Debug
                printf "%s is behind, pulling in latest commits \n" "$folder"

                # Fetch Remote
                git fetch >/dev/null
                if [ ! $? -eq 0 ]; then
                    printf "    - Failed to fetch remote\n"
                    continue
                fi

                # Pull from remote
                git pull >/dev/null
                if [ ! $? -eq 0 ]; then
                    printf "    - Failed to pull commits from remote\n"
                    continue
                else
                    printf "    - Successfully pulled new commits from remote\n" "$folder"
                fi
            fi
        else
            printf "Failure - %s does not have a remote \n" "$folder"
            continue
        fi

        # Change back to root dir
        cd ../..
    fi
done
