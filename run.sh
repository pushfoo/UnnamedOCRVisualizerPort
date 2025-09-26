#!/usr/bin/env sh

usage() {
cat << EOF
$0 [OPTIONS (passthru to Love2D) ]

Packs the source into a .love file and runs it.

IMPORTANT: This script assumes you love2d in your PATH or aliases!

It works by:
1. zipping the contents of src into a bin/project.love file
2. running it with all args passed through 

See:

- src/main.lua for any flags or arguments once implemented
- https://love2d.org/ for more info on Love2D

EOF
}

# Love2D doesn't appear to have --help support? What?
if [ "$#" -eq 1 ] && [ "$1" == "--help" ]; then
    usage
fi

# Actually pack + run the thing
mkdir -p bin
cd src
zip -9 -r ../bin/project.love .
cd ..
love2d bin/project.love "$@"

