# Get latest alpine image
FROM alpine:latest

# Update image and install git
RUN apk --update add bash git less openssh && \
    rm -rf /var/lib/apt/lists/* && \
    rm /var/cache/apk/*

# Add git variables
ENV PULL_DELAY 10
ENV PUSH_DELAY 1

# Copy across files from utilities
COPY scripts/* /scripts/

# Run shell when starting container
CMD /bin/sh scripts/git_run.sh