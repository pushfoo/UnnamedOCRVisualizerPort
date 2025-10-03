# UnnamedOCRVisualizerPort

A WIP partial port of an unreleased OCR visualization tool.

## Requirements

So far:

1. [Love2D][] >= 12.0
   - This is a prerelease version
   - See [build info](#building-love2d-12)
2. [Tesseract][] for OCR

[Tesseract]: https://github.com/tesseract-ocr/tesseract

## Why?

1. Refresh myself on Lua
2. See how [Love2D][] has progressed

[Love2D]: https://love2d.org/

## What's Supported?

Goals include:

-[X] [Tesseract][]-style [TSV][] output
 - [X] Minimal color mapping
 - [X] System filepicker to choose files
-[ ] Minimal UI:
  -[ ] Mouse-based gestures
  -[ ] Hot keys

XML-based [ALTO][] *may* also happen, but it's not a
priority given this is a port of an existing tool.


[Tesseract]: https://github.com/tesseract-ocr/tesseract
[TSV]: https://en.wikipedia.org/wiki/Tab-separated_values
[ALTO]: https://en.wikipedia.org/wiki/Analyzed_Layout_and_Text_Object

## How do I use `run.sh`?

**TL;DR:** Install [Love2D][] + [Tesseract][] before `./run.sh`

> [!WARNING]
> Debian is not Ubuntu! (See [next section](#debian-and-other-appimage-users))

### Build Love2D 12.0's Pre-Release

Love2D's upcoming 12.0 release offers performance and API improvements even as an unfinished work in progress.

This means you currently have to build it from source to use this project. On Debian, you can use `sudo ./get_deps.sh` to get known build dependencies.

On other operating systems or Linux distros, you may need to consult the following:
* The [Love2D dependencies list][]
* The relevant documentation for your package manager
* The [Love2D compilation instructions][]

On sufficiently Debian-like Linux, `sudo ./get_deps.sh force` **may** work. However, it's best to double check.

[Love2D dependencies list]: https://github.com/love2d/love?tab=readme-ov-file#dependencies
[Love2D compilation instructions]: https://github.com/love2d/love?tab=readme-ov-file#compilation

### Add your Love2D v12.0 to `$PATH`

Once you've compiled, find the `build/` folder in the cloned Love2D repo. Then do one of the following to add the new Love2D 12.0 to your `PATH` as `love12.0`

- copy the file to install it
- link it into a `~/bin` folder
- alias it in your `.bashrc`

> [!NOTE]
> You can also skip `./run.sh` and use your own build/runner script.

### Building the `.love` file

The `./run.sh` script auto-packages a `.love` file from
the source folder.

```shell
$ ./run.sh
```
All arguments after are passed through directly.

### Future Considerations

You'll want to use the [AppImage][] for Love2D 12.0 once it releases, especially on Debian.

This will ensure you avoid creating a [FrankenDebian].


[FrankenDebian]: https://wiki.debian.org/DontBreakDebian#Don.27t_make_a_FrankenDebian
[AppImage]: https://appimage.org/
[cloning the repo]: https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository

