#!/usr/bin/env bash

# Runs a busted script locally form either global or local install.
#
# If the script finds an install in any of these locations, args
# will be forwarded to the application:
#
# 1. The default location shown via which busted
# 2. The local userdir installation
#
# If none are found, it exits with an error + error return code of 1.

BUSTED_CMD="$(which busted)"
LUAROCKS_USERDIR_BIN="/home/$USER/.luarocks/bin"

if [ -z "$BUSTED_CMD" ]; then
    # echo "NOT_FOUND: \$(which busted)"
    if [ -d "$LUAROCKS_USERDIR_BIN" ]; then
        BUSTED_CMD="$LUAROCKS_USERDIR_BIN/busted"
    else
        echo "NOT_FOUND: $LUAROCKS_USERDIR_BIN (typical location for luarocks --local)"
    fi
fi

if [ -z "$BUSTED_CMD" ]; then
    echo "Failed to find a known install of busted!"
    exit 1
fi

$BUSTED_CMD $@
