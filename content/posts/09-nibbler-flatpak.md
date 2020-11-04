---
title: "Flatpak-ing Nibbler, a Leela Chess Zero Interface and some Neural Network Engines"
date: 2020-10-30T17:39:23-03:00
draft: false
---

> Article by editor Leo <thinkabit.ukim@gmail.com>  

> The Machine Learning terminology here is simplified and will have a loss
> quality, but not pertinent to the point.

Nibbler is a Graphical User Interface to analyse chess games using mainly
the [Leela Chess Zero][1] chess engine (software that plays chess and provides
an evaluation of positions). It is written specifically for using Leela.

Nibbler is written specifically to make use of Leela's output. While traditional
engines ouptut centipawns to indicate how much hundredths of a pawn either side
is ahead. Leela outputs what it believes what is the Win, Draw and Loss chance
for the current side, along with how certain it is of its evaluation and other
information like how many moves left until the games reaches its conclusion.

Unfortunately for us it is written in Electron which makes it very hard to package
for [musl][2] systems like [Alpine Linux][3] which I use and am a developer of.
Fortunately there is [flatpak][4] which is a godsend for packaging heavyweight apps,
so lets go package it.

<!--more-->

## Writing the boilerplate

Lets start by writing the boilerplate we need to get started on any Flatpak app.

```yaml
app-id: org.fohristiwhirl.nibbler
runtime: org.freedesktop.Platform
runtime-version: '20.08'
branch: stable
sdk: org.freedesktop.Sdk
command: /app/nibbler/nibbler

finish-args:
  - --share=ipc # Needed for X11
  - --socket=x11 # Electron needs Ozone to support Wayland but it is not there yet
  - --device=dri # need access to the GPU
  - --filesystem=xdg-data # Access to $XDG_DATA_HOME, letting the user load networks
```

## Writing the module

Now lets package Nibbler itself, in this case we will use the pre-packaged Nibbler
for Glibc x86_64 instead of compiling Electron ourselves, which is rather time intensive.

```yaml
modules:
    - name: nibbler
    buildsystem: simple
    sources:
      - type: archive
        url: https://github.com/fohristiwhirl/nibbler/releases/download/v1.5.7/nibbler-1.5.7-linux.zip
        sha256: f64d7fc89f5cd68b41dccff4fc7aa2f03a482750f2d7fa6af522f78d74264f4d
      - type: file
        path: org.fohristiwhirl.nibbler.desktop
        sha256: 75ce7081b35321eeeb80043483a6977babe11055ed41f3a22cc718b63fabc6fa
    build-commands:
      - |
        install -Dm0644 org.fohristiwhirl.nibbler.desktop -t /app/share/applications
        mkdir -p /nibbler
        mv * /nibbler
        mkdir -p /app
        mv /nibbler /app
        chmod +x /app/nibbler/nibbler
```

### .desktop file

Nibbler itself has no .desktop file, so let's write one for it. One can notice that
`--no-sandbox` is passed, which is required because Flatpak doesn't allow SUID or
root-owned binaries, which are required for Electron's sandbox.

```ini
[Desktop Entry]
Name=Nibbler (Flatpak)
Comment=Leela Chess Zero (Lc0) Interface
Exec=/app/nibbler/nibbler --no-sandbox %U
Icon=Nibbler
StartupNotify=true
Terminal=false
Type=Application
Categories=Game
```

### Packaging Lc0

Now the hardest part, packaging the Neural Network Engine itself. Neural Network chess
engines have two main components:

1. A binary which looks at a position on a chess board and uses a neural network
   to derive information from the position, such as the expected win rate for each
   side (or draw), the certainty of those win rates, and how many moves are left before
   the conclusion of the game. All that information and more is passed to Nibbler.
2. A weights file, which is a representation of a Neural Network that was trained through
   either playing itself, observing high-level games, or both. Storing in it the useful
   connections (like a super simple model of a brain) that allow it to evaluate a position
  on a chess board with great accuracy.

Lets package them, by starting with the dependencies of lc0. These can be found in
[Flathub's repos][9] as they are used in other Flatpak-ed packages:

```yaml
  - name: eigen
    buildsystem: cmake-ninja
    builddir: true
    sources:
     - type: archive
       url: https://gitlab.com/libeigen/eigen/-/archive/3.3.8/eigen-3.3.8.tar.gz
       sha256: 146a480b8ed1fb6ac7cd33fec9eb5e8f8f62c3683b3f850094d9d5c35a92419a
  - name: openblas
    no-autogen: true
    make-args:
      - DYNAMIC_ARCH=1
      - FC=gfortran
      - NO_LAPACKE=1
      - USE_OPENMP=0 # OpenMP off by default, this hack skips 'test_fork' which crashes on i386
    make-install-args:
      - PREFIX=/app
    sources:
      - type: archive
        url: https://github.com/xianyi/OpenBLAS/archive/v0.3.12.tar.gz
        sha256: 65a7d3a4010a4e3bd5c0baa41a234797cd3a1735449a4a5902129152601dc57b
```

And now we package lc0 and the weights file it uses. Under default settings the weights
need to be in the same directory as the executable and be named `nn`.

```yaml
  - name: lc0
    buildsystem: meson
    config-opts:
      - -Dopenblas=true
      - -Dopenblas_libdirs=/app/lib
      - -Dgtest=false
      - -Db_lto=true
      - -Dopencl=false
    sources:
      - type: git
        url: https://github.com/LeelaChessZero/lc0
        tag: v0.26.3
  - name: nn
    buildsystem: simple
    build-commands:
      - |
        mkdir -p /app/bin
        mv nn /app/bin
    sources:
      - type: file
        dest-filename: nn
        url: https://training.lczero.org/get_network?sha=4df05b0f0e80523018c073fd151ba26d955140ba303e84cebd96e027c6e06a3e
        sha256: 821aabc4316d49a526ba737a218fb868dd7c72c5e7b1a91eb8e6c805e3503028
```

This is good enough, but let's go further.

### Packaging a NNUE Chess Engine

There is a different Neural Network type than the one used by lc0, called
[Efficiently Updatable Neural Networks][5]. It is much smaller and gives
less outputs that can be used by Nibbler but it is fast on CPUs, specially
with instructions like AVX512, while Leela excels when using GPUs specially
RTXes with CUDA.

So let's package [cfish][6], a C rewrite of [Stockfish][7]:

```yaml
  - name: cfish-pure-NNUE
    buildsystem: simple
    build-options:
      env:
        ARCH: x86-64-bmi2
        COMP: clang
        COMPXX: clang++
    build-commands:
      - |
        # Replace their network with the one we want to use, in this case it is
        # dark horse 0.2a "Aldi"
        # Taken from: https://www.patreon.com/posts/dark-horse-0-2a-40420324
        sed -i 's|nn-2eb2e0707c2b.nnue|nn-c2fd094bce06.nnue|' src/evaluate.h
        # Move the Neural Network to src, so we don't need to download it
        mv nn-c2fd094bce06.nnue src
        # Farthest I can go in my CPU, others might want to use avx512, vnni256
        # or even vnni512 instead
        make -C src build nnue=yes pure=yes embed=yes numa=no lto=yes extra=yes
        install -Dm0755 src/cfish -t /app/bin
    sources:
      - type: git
        url: https://github.com/syzygy1/Cfish.git
        commit: b5576f28b82828143fad03b52d3f041240204d6c
      - type: file
        path: nn-c2fd094bce06.nnue
        sha256: c2fd094bce06942e882a7526a7443007a511ed5ee256613cf3a60a9f4ac744e8
```

This will give us a binary called `cfish` that has an embedded NNUE network in it
which guarantees it will always work, as long as you have a CPU that supports the
instructions enabled by `bmi2`. Those with more modern CPUs might want to go even
further and enable AVX512 or even VNNI by changing `x86-64-bmi2` to the appropriate
value.

### Wrapping up

In this article we have packaged a Chess GUI Interface for Leela, Leela itself,
a very strong weights file for Leela to use and an engine that uses a different
type of Neural Network that is meant for CPU users.

All this and more (another Stockfish engine, patches for different functionality
in Nibber) can be found in my [Nibbler-flatpak][8] repository.

[1]: https://lczero.org
[2]: https://musl.libc.org
[3]: https://alpinelinux.org
[4]: https://flatpak.org
[5]: https://www.chessprogramming.org/NNUE
[6]: https://github.com/syzygy1/Cfish
[7]: https://stockfishchess.org
[8]: https://github.com/maxice8/nibbler-flatpak
[9]: https://github.com/flathub
