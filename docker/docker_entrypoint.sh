#!/bin/bash
set -e

# This script designed to be used a docker ENTRYPOINT "workaround" missing docker
# feature discussed in docker/docker#7198, allow to have executable in the docker
# container manipulating files in the shared volume owned by the USER_ID:GROUP_ID.
#
# It creates a user named `aosp` with selected USER_ID and GROUP_ID (or
# 1000 if not specified).

# Example:
#
#  docker run -ti -e USER_ID=$(id -u) -e GROUP_ID=$(id -g) imagename bash
#

# Reasonable defaults if no USER_ID/GROUP_ID environment variables are set.
if [ -z ${USER_ID+x} ]; then USER_ID=1000; fi
if [ -z ${GROUP_ID+x} ]; then GROUP_ID=1000; fi

msg="docker_entrypoint: Creating user UID/GID [$USER_ID/$GROUP_ID]" && echo $msg
groupadd -g $GROUP_ID -r yewkui && \
useradd -u $USER_ID --create-home -r -g yewkui yewkui
echo "$msg - done"

msg="docker_entrypoint: Copying .gitconfig and .ssh/config to new user home" && echo $msg
cp /root/.gitconfig /home/yewkui/.gitconfig && \
chown aosp:aosp /home/yewkui/.gitconfig && \
mkdir -p /home/yewkui/.ssh && \
cp /root/.ssh/config /home/yewkui/.ssh/config && \
chown aosp:aosp -R /home/yewkui/.ssh &&
echo "$msg - done"

msg="docker_entrypoint: Creating /tmp/ccache and /aosp directory" && echo $msg
mkdir -p /tmp/ccache /yewkui
chown yewkui:yewkui /tmp/ccache /yewkui
echo "$msg - done"

echo ""

# Default to 'bash' if no arguments are provided
args="$@"
if [ -z "$args" ]; then
  args="bash"
fi

# Execute command as `aosp` user
export HOME=/home/yewkui
exec sudo -E -u yewkui $args
