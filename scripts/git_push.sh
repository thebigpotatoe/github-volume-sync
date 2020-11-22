#!/bin/sh

set -o errexit
set -o nounset
set -o pipefail

# Walk each of the directories in the data folder
for folder in $DATA_LOCATION/*; do
    # Change into dir if git repo exists
    cd $folder

    # Check for a git repo in dir
    if [ -d .git ]; then
        # Check for a remote
        remote_urls=$(git remote -v)
        if [ ! -z remote_url ]; then

            # Get the list of untracked files
            # UNTRACKED=$(git status --porcelain 2>/dev/null | grep "^??" | wc -l)
            MODIFIED=$(git ls-files -o -m | wc -l)
            STAGED=$(git ls-files -o -m | wc -l)
            COMMITTED=0

            # If repo has changes push to remote
            if [ ! "$MODIFIED" -eq "0" ] || [ ! "$COMMITTED" -eq "0" ]; then
                # Debug
                printf "%s - Modifications found\n" "$folder"

                # Get update from remote
                git remote update >/dev/null
                if [ ! $? -eq 0 ]; then
                    printf "Failed to updated from remote"
                    continue
                fi

                # If repo has not diverged push the latest updates
                if [ ! $(git status -uno | grep -q diverged) ]; then
                    # Debug
                    printf "    - Out of sync with remote\n"

                    # Pull in changes incase behind
                    if [ $(git status -uno | grep -q behind) ]; then
                        printf "    - Currently behind, pulling latest commits \n"
                        git pull >/dev/null
                        if [ ! $? -eq 0 ]; then
                            printf "    - Failed to pull from remote"
                            continue
                        fi
                    fi

                    # Commit all new changes
                    commit_msg=$(printf "Automatic commit from docker at: %s" "$(date)")
                    git add -A >/dev/null
                    git commit -m "$commit_msg" >/dev/null
                    # if [ ! $? -eq 0 ]; then
                    #     printf "    - Failed to commit changes"
                    #     exit 1
                    # fi

                    # Could check here if there is a clash or divergence then revert the last commit
                    if [ $(git status -uno | grep -q unmerged) ]; then
                        printf "    - Warning, the last series of commits created a branch. Please check the diff to solve \n"
                        git reset --soft HEAD~1
                    else
                        printf "    - Pushing latest commit to remote \n"
                        git push --quiet >/dev/null
                        if [ ! $? -eq 0 ]; then
                            printf "    - Failed to push from remote"
                            continue
                        fi
                    fi

                    # Debug
                    printf "    - Done \n"
                else
                    printf "    - Diverged, not pushing new data to avoid conflicts \n" "$folder"
                fi
            fi
        else
            printf "Failure - %s has no remote\n" "$folder"
        fi
    else
        printf "Failure - %s has no git repository\n" "$folder"
    fi

    # Change back to root dir
    cd ../..
done

exit 0
