#!/usr/bin/env bash


exit_nondebian() {
    echo "ERROR: This is a Debian-only helper script for now :(" >&2
    exit 1
}

source <(cat /etc/os-release)
if [ "$ID" != "debian" ]; then
    if [ "$1" != "force" ]; then
        exit_nondebian
    fi
fi

apt install\
    libfreetype-dev\
    libluajit-5.1-dev\
    libvorbis-dev\
    libmodplug-dev\
    libopenal-dev\
    libsdl3-dev\
    libharfbuzz-dev


