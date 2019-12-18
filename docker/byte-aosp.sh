#!/bin/bash

# set -x

# SDIR store this script path
SDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# SNAME store the script name
SNAME="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"

# check for directory architecture
AOSPDIR="${SDIR}"
IMAGE="bytedance-aosp"
CONTAINER="android-build"

############################################################
#### Library for common usage functions

function INFO {
    : << FUNCDOC
This function print the MSG with "INFO:" as prefix, and add newline after MSG

parameter 1: MSG -> message for info

FUNCDOC
    echo -e "\x1b[92m\x1b[1mINFO\x1b[0m:"
    echo -e "\e[92m\e[1mINFO\e[0m: ${1}\n"
}

function ERROR {
    : << FUNCDOC
This function print the MSG with "ERROR:" as prefix, and add newline after MSG

parameter 1: MSG -> message for info

FUNCDOC

    echo -e "\e[31m\e[1mERROR\e[0m: ${1}\n"
}

############################################################

function usage {
    cat <<EOF

Usage: $0 <arguments>

Arguments:

    -b, --buildenv  : build docker image
    -w, --workdir   : aosp workspace to shared with docker container
    -r, --rm        : remove current working container
    -h, --help      : show this help info

Description:

    First thing first, copy $0 to PATH:

        cp $0 ~/bin/android-build

    First time use, need to build the docker image by:

        $0 --buildenv

    To run a build script, do this:
    
        $0 --workdir <path-to-aosp-project> ./build.sh

    Or, if you want to do it interactively, just:

        $0 --workdir <path-to-aosp-project>

    When container is running, you can open extra shell terminal with:

        $0 --shell

    Each time the build is done, the container will be removed automatically,
    but if it's interupted and not properly exited, you can remove it by:

        $0 --rm

EOF
}

# NOTE: This requires GNU getopt.  On Mac OS X and FreeBSD, you have
# to install this separately
TEMP=`getopt -o w:W:brhs --long workdir:,buildenv,rm,help,shell -- "$@"`

if [ $? != 0 ] ; then
    usage
    exit 1
fi

# if no argument
if [ -z "$1" ] ;then
    usage
    exit 1
fi

# parsing arguments
while true
do
    case "$1" in
    -h | --help)
        usage; exit 0
        ;;
    -r | --rm)
        if docker inspect $CONTAINER > /dev/null 2>&1 ; then
            INFO "Remove container: $CONTAINER"
            docker rm $CONTAINER
        else
            INFO "container: $CONTAINER not exist, no need to remove"
        fi
        exit $?
        ;;
    -w | --workdir)
        AOSPDIR=$(readlink -m "$2")
        INFO "Creating container $CONTAINER"
        docker run --rm -it \
            --volume="${AOSPDIR}:/aosp" \
            --volume="${HOME}/.profile:/home/${USER}/.profile" \
            --volume="${HOME}/.bashrc:/home/${USER}/.bashrc" \
            --volume="${HOME}/.ssh:/home/${USER}/.ssh" \
            --volume="${HOME}/.gitconfig:/home/${USER}/.gitconfig" \
            --volume="/etc/localtime:/etc/localtime:ro" \
            --name=${CONTAINER} \
            ${IMAGE} \
            ${@:3}
        exit $?
        ;;
    -W)
        AOSPDIR=$(readlink -m "$2")
        INFO "Creating container $CONTAINER"
        docker run --rm \
            --volume="${AOSPDIR}:/aosp" \
            --volume="${HOME}/.profile:/home/${USER}/.profile" \
            --volume="${HOME}/.bashrc:/home/${USER}/.bashrc" \
            --volume="${HOME}/.ssh:/home/${USER}/.ssh" \
            --volume="${HOME}/.gitconfig:/home/${USER}/.gitconfig" \
            --volume="/etc/localtime:/etc/localtime:ro" \
            --name=${CONTAINER} \
            ${IMAGE} \
            ${@:3}
        exit $?
        ;;
    -b | --buildenv)
        docker build \
            --build-arg USER_NAME=${USER} \
            --build-arg HOST_UID=$(id -u ${USER}) \
            --build-arg HOST_GID=$(id -g ${USER}) \
            -t ${IMAGE} .
        exit $?
        ;;
    -s | --shell)
        docker exec -it ${CONTAINER} bash
        exit $?
        ;;
    *)
        usage
        exit $?
        ;;
    esac
done

# bye
exit $?
