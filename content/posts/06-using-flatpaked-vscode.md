---
title: "Using VSCode in a Flatpak"
date: 2020-03-27T09:25:10+0100
draft: false
---

I've recently started using VSCode as my main editor, mainly due to its
extensibility, meaning I can use it in almost all scenarios (at work, for
personal projects, ...) and it's easy to customize to my needs (although the
defaults are pretty nice already). However, since it uses Electron (which
currently still needs glibc, [although that might change soon](https://github.com/electron/electron/issues/9662#issuecomment-591719521))
I currently need to run it in a Flatpak, which needed some setup in order
to be suitable for development

<!--more-->

# Setting up dependencies

Overall, there are two ways to do this: The (somewhat) quick and messy way
and the less quick but _way_ nicer way.

## The messy way

Flatpak mounts folders in its / read-only, so you don't mess with it, so you
can't really install deps there, unless you bindmount a folder into the VSCode
flatpak, like so:

```sh
flatpak override --filesystem=/packages com.visualstudio.Code
```

Alternatively you could also use one of the folders in your $HOME, since the
VSCode flatpak permits full access to $HOME through the sandbox. You can now
build packages and install them to your new folder (which boils down to downloading the tarball, runing
`./configure --prefix=/packages && make install` or `meson --prefix=/packages build && ninja -C build install`
or something along those lines). Afterwards you have to adjust some environment
variables so that VSCode is able to find your new libs:

```sh
flatpak override --env=LD_LIBRARY_PATH=/packages/lib --env=LIBRARY_PATH=/packages/lib --env=PKG_CONFIG_PATH=/packages/lib --env=GETTEXTDATADIRS=/packages/share/gettext
```

The disadvantage of this method is that it's not really reproducible (which is annoying
if you have multiple systems), prone to breaking and while it is easy to setup it
will probably be more annoying in the long run when updating packages

## The less messy way

It's possible to create so called Sdk-Extensions which can then be used in your Flatpak.
This means creating a build recipe in a YML file and building it with `flatpak-builder`
and installing it. A simple build recipe which only builds one package could look like this:

```yml
# app-id, you can set this to whatever if you want to
app-id: org.freedesktop.Sdk.Extension.Cogitri
# The branch this extension is for. Make sure to keep this in sync with
# runtime-version
branch: '19.08'
runtime: org.freedesktop.Sdk
# What version the runtime we build against has. Make sure this is the same
# version as VSCode uses!
runtime-version: '19.08'
sdk: org.freedesktop.Sdk
build-extension: true
build-options:
  # We want to install to this dir. This is passed to CMake/Meson/Configure etc.
  # if you set the `buildsystem` (see below in the vte module)
  prefix: /usr/lib/sdk/Cogitri
  # This is only required if one of the dependencies you build needs a binary from
  # another package you build in this module
  prepend-path: /usr/lib/sdk/Cogitri/bin
  # Same as above, but for libraries instead of binaries
  prepend-ld-library-path: /usr/lib/sdk/Cogitri/lib
modules:
  # It's best to make one module here for every dependencies you need, since flatpak
  # caches per-module: If you bump the dependency of one module you don't need to
  # rebuild everything then
  - name: vte2.91
    buildsystem: meson
    config-opts:
      - -Ddocs=false
      - -Dvapi=false
    build-options:
      env: { CXXFLAGS: "-fno-exceptions" }
    sources:
      - type: archive
        url: https://download.gnome.org/sources/vte/0.58/vte-0.58.3.tar.xz
        sha256: 22dcb54ac2ad1a56ab0a745e16ccfeb383f0b5860b5bfa1784561216f98d4975
```

See [man 5 flatpak-manifest](https://jlk.fjfi.cvut.cz/arch/manpages/man/flatpak-manifest.5.en) for
more information. See [my GitHub repo](https://github.com/Cogitri/org.freedesktop.Extension.Cogitri/blob/master/org.freedesktop.Sdk.Extension.Cogitri.yml) for how I made my build recipe.

Once you're done adding all packages to your build recipe it's time to build it like this:

```
flatpak-builder --user --install --force-clean app org.freedesktop.Sdk.Extension.Cogitri.yml
```

This will build and install your extension for you. The only thing that's left now is to adjust
your paths:

```sh
flatpak override --env=LD_LIBRARY_PATH=/usr/lib/sdk/Cogitri/lib --env=LIBRARY_PATH=/usr/lib/sdk/Cogitri/lib --env=PKG_CONFIG_PATH=/usr/lib/sdk/Cogitri/lib --env=GETTEXTDATADIRS=/usr/lib/sdk/Cogitri/share/gettext
```

And now your dependencies should be available in your flatpak! :)

### Updating dependencies

Updating dependencies is pretty easy with this approach. For example if I want to bump vte2.91
to version 0.60.0 I only need to change two things: the `url` to point at `0.60.0` instead of
`0.58.3` and the `sha256` to be the sha256sum of the new tarball. Flatpak has some fancy tool
to automatically update the sha256sum for you, but I forgot it's name - and `curl $url | sha256sum`
does the trick for now :)
After updating your build recipe simple re-run flatpak-builder like above. Since flatpak will only
rebuild changed modules (and modules that are built after that module, in case the other modules
need the changes of that new module) it shouldn't take as long as the initial build. It's a good
idea to place dependencies which are updated often to at the end of the file, so you don't have
to rebuild as many modules when bumping it.
