# QGIS on Apple Silicon

This project aims to build and package [QGIS](https://www.qgis.org) on macOS for ARM64. We use [Homebrew](https://brew.sh) to bootstrap build environment with [additional formulae](https://github.com/DingoBits/homebrew-dingobits) to fulfill dependencies.

This is a work in progress. Builds are experimental and bugs are to be expected. Due to complex dependencies and numerous workarounds, a fully-featured build will not be available soon.

## Table of Contents

1. [Caveats](#caveats)
2. [Ways to Install](#ways-to-install)
3. [Building](#building)
4. [Packaging](#packaging)

---

## Caveats

QGIS currently only supports Qt 5, (the open source version of) which doesn’t officially support Apple Silicon. QGIS also relies on QtWebkit, which was depreciated a year before Apple Silicon launched and requires an increasing amount of patches to build. This means **bugs are to be expected**. If you run into one that’s not present in the official AMD64 build, [file an issue](https://github.com/DingoBits/qgis-arm64-apple/issues).

**Proprietary libraries, including ERDAS ECW/JP2, MrSID, Oracle Spatial Database and SAP HANA, are currently not available** since none of them have released an arm64 version for macOS.

I only use a subset of features that QGIS offer, which means **some features will be relatively untested** beyond `make test`. If you encounter a bug, [file an issue](https://github.com/DingoBits/qgis-arm64-apple/issues). I also don’t have the time or the energy to create a full-featured build at the moment (it’ll take weeks of full-time work). My plan is to create a build per QGIS release and troubleshoot along the way, hopefully to come up with a fully functional build script down the road,

## Ways to Install

### 1. Install Pre-packaged QGIS (The Easy Way) 

I maintain a packaged QGIS for my own use, which is also [released in this repo](https://github.com/DingoBits/qgis-arm64-apple/releases). Check out the release page for missing features, dependencies used and other build information for each release. 

In principle, you shouldn’t trust binaries from random strangers, but I trust myself.  My builds are not codesigned, which means you must right-click when you open the app for the first time, or you will encounter an error message subtly implying I didn’t pay Apple $100/year for the privilege of having them check the app.

### 2. Install from Homebrew Cask

I maintain [a Homebrew tap](https://github.com/DingoBits/homebrew-dingobits) for the pre-packaged QGIS, as well as some of its dependencies. This will allow homebrew to automatically update QGIS when I release a new version. To install:

```
brew install --cask dingobits/dingobits/qgis-arm64
```

### 3. Install from MacPorts

Unrelated to this project, [Veence](https://github.com/Veence) maintains [a QGIS port for MacPorts](https://ports.macports.org/port/qgis3/details). Unlike Homebrew Cask,  **MacPorts will build QGIS instead of downloading a pre-packaged version**, which may take a long time. **`brew` and `ports` are potentially incompatible**, so it’s best to stick to your preferred package manager. To install:

```
sudo ports install qgis3
```

Please reach out to the MacPorts community if you encounter any issues.

### 4. Install the official x64 Package with Rosetta

If you need some of the missing features, such as ERDAS ECW/JP2, your best option is to use [the official x64 package](https://qgis.org/en/site/forusers/download.html) with Rosetta.

Alternatively, you can use a GNU/Linux distribution with aarch64 packages for QGIS  (e.g. Arch, Debian, Fedora) in a virtual machine or on [Asahi Linux](https://asahilinux.org).

## Building

I maintain [a build script that bootstraps from homebrew](https://github.com/DingoBits/qgis-arm64-apple/blob/main/build.sh). At this time, **the script is for reference only** as it’s neither complete nor fully tested. If you run the script, it’s highly likely that the build will fail at a certain point. I recommend you to follow the script in terminal, and use `ccmake` for troubleshooting.

If you’re brave enough to do it truly from the scratch, I applaud your spirit but I’m afraid you’re on your own. That being said, I do offer some [patches](https://github.com/DingoBits/qgis-arm64-apple/tree/main/patches) to help you along the way.  Also, I recommend at least 16 GB of RAM, as compiling Python bindings alone can use up to 8 GB of RAM, and consume your SSD for SWAP at 200GBW/hour.

## Packaging

If you don’t intend to distribute your QGIS build, the app bundle in `build/output/bin/QGIS.app` would suffice. However, packaging for distribution is not as straightforward.

As per QGIS documentation, if  you build QGIS with `-DQGIS_MACAPP_BUNDLE=1`, `make install` *should* automatically package a complete build in `CMAKE_INSTALL_PREFIX`, but it doesn't work properly. Most libraries won't be packaged, and  many packaged library will still have their paths pointed to homebrew.  The result is two copies of the same library gets loaded into memory and causes segfault.

The solution at the moment involves a little manual labour. Use `macdeployqt` to continue packaging a more complete build, and then manually add still missing libraries, e.g. Python. Copy the necessary Python modules to `Resources/python`. Then rewrite install paths with `install_name_tool` in `Frameworks` and `PlugIns`. You can automate this step with `for` loop. For example,

```
for i in *.dylib
	install_name_tool -id "@executable_path/../PlugIns/$i" "$i"
end
```

