# UnnamedOCRVisualizerPort

A WIP partial port of an unreleased OCR visualization tool.

## Requirements

So far:

1. [Love2D][] >= 11.5
2. A source of data (not yet implemented)

## Why?

1. Refresh myself on Lua
2. See how [Love2D][] has progressed

[Love2D]: https://love2d.org/

## What's Supported?

Goals include:

-[ ] [Tesseract][]-style [TSV][] output
-[ ] Minimal UI:
  -[ ] Mouse-based gestures
  -[ ] Hot keys

XML-based [ALTO][] *may* also happen, but it's not a
priority given this is a port of an existing tool.


[Tesseract]: https://github.com/tesseract-ocr/tesseract
[TSV]: https://en.wikipedia.org/wiki/Tab-separated_values
[ALTO]: https://en.wikipedia.org/wiki/Analyzed_Layout_and_Text_Object

## How do I use `run.sh`?

### Ubuntu-likes can use the PPA Instead

> [!WARNING]
> **NEVER** mix Ubuntu packages with Debian! (See [next section](#debian-and-other-appimage-users)

Users on Ubuntu and compatible distros can use the [Love2D PPA][]:

- Ubuntu
- Pop!_OS
- Linux Mint

### Debian and Other AppImage Users

Debian is best served by the Love2D AppImage to [avoid breaking Debian][FrankenDebian].

This script eases file and folder access restrictions on [AppImage][]s.
Use it as follows after [cloning the repo][]:

1. `mkdir -p ~/bin`
2. Download [Love2D][] to `~/bin`
3. `cd ~/bin`
4. `ln -s name_of_app_image.file love2d`
5. `cd ..`
6. `./run.sh`

[FrankenDebian]: https://wiki.debian.org/DontBreakDebian#Don.27t_make_a_FrankenDebian
[AppImage]: https://appimage.org/
[cloning the repo]: https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository

