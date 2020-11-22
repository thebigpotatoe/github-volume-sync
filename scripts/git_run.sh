#!/bin/sh

# Set exit codes
set -o errexit
set -o nounset
set -o pipefail

# Starting debug
printf "*** Started main bash script ***\n"

# Get the update periods from env
printf "Setting git status delay periods\n"
if [ ! -z "$PULL_DELAY" ] && [ ! -z "$PUSH_DELAY" ]; then
    pull_delay=$PULL_DELAY
    push_delay=$PUSH_DELAY
    printf "    - Success - Using input values for push and pull delay of %d and %d seconds\n" "$pull_delay" "$push_delay"
else
    pull_delay=10
    push_delay=1
    printf "    - Success - Using default values for push and pull delay of %d and %d seconds\n" "$pull_delay" "$push_delay"
fi

# Setup timer variables
last_pull_time=$(date +%s)
last_push_time=$(date +%s)

# Set the credentials from environmental variables
printf "Setting git global credentials\n"
if [ -z "$EMAIL" ] && [ -z "$NAME" ]; then
    printf "    - Failure - No credentials found in environmental variables\n"
    exit 1
else
    git config --global user.email "$EMAIL" &&
        git config --global user.name "$NAME"
    printf "    - Success - Set username to \"%s\" and email to \"%s\"\n" "$NAME" "$EMAIL"
fi

# Get the private key file from the chosen source
printf "Searching for SSH key\n"
mkdir /home/.ssh
if [ ! -z ${ID_RSA+x} ]; then
    printf "    - Success - Using insecure ENV private key for GitHub\n"
    printf "$ID_RSA" >/home/.ssh/id_rsa
    unset ID_RSA
elif test -f "/run/secrets/id_rsa"; then
    printf "    - Success - Using private key passed through secrets for GitHub\n"
    cat  /run/secrets/id_rsa > /home/.ssh/id_rsa
else
    printf "    - Failure - Could not find a private key, please add one and try again\n"
    exit 1
fi

# Start the SSH agent
printf "Starting SSH Agent\n"
echo  >> /home/.ssh/id_rsa
chmod 400 /home/.ssh/id_rsa
eval "$(ssh-agent -s)" >/dev/null
if [ "$?" -eq 0 ]; then
    ssh-add /home/.ssh/id_rsa #2>/dev/null
    printf "    - Success - Started SSH agent\n"
else
    printf "    - Failure - Could not start SSH agent\n"
    exit 1
fi

# Add Github as a known host
printf "Adding GitHub as Known Host\n"
mkdir /root/.ssh/
touch /root/.ssh/known_hosts
githubkey=$(ssh-keyscan github.com 2>/dev/null)
if [ ! -z "$githubkey" ]; then
    echo $githubkey >>/root/.ssh/known_hosts
    printf "    - Success - Added GitHub as known host\n"
else
    printf "    - Failure - Could not add GitHub as known host\n"
    exit 1
fi

# Clone in required repo's
printf "Cloning required repositories\n"
bash scripts/git_clone.sh

# Run push and pull forever
printf "\n*** Started main loop ***\n"
while true; do
    # Pull every 15 seconds
    if [ "$(expr $last_pull_time + $pull_delay)" -lt "$(date +%s)" ]; then
        bash scripts/git_pull.sh
        last_pull_time=$(date +%s)
    fi

    # Run push every second
    if [ "$(expr $last_push_time + $push_delay)" -lt "$(date +%s)" ]; then
        bash scripts/git_push.sh
        last_push_time=$(date +%s)
    fi

    # Sleep to use less cpu
    sleep 1
done
