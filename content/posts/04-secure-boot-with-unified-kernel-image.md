---
title: "Booting Alpine Linux with a Unified Kernel Image and Secure Boot"
date: 2020-02-02T06:07:10+0100
draft: false
aliases:
    - /posts/04-secure-boot-with-unified-kernel-image/
    - /post/04-secure-boot-with-unified-kernel-image/
---

# Introduction

> Guest article by maxice8

Recently I got myself into package `sd-boot` from the Systemd project
into Alpine Linux. I previously packaged it as an April's fools joke
for Void Linux [Here](https://github.com/void-linux/void-packages/pull/10469/).

After receiving some negative feedback on including it, more specifically
about the fact I had to include 23 patches (which could be trimmed but would
be more work than just copying the work of the
[OpenEmbedded](http://www.openembedded.org/wiki/Main_Page) and
[NixOS Musl](https://github.com/NixOS/rfcs/blob/master/rfcs/0023-musl-libc.md)
people) to make it compile.

A side-effect of packaging `sd-boot` is that I got into, and learnt a
few things about booting directly from UEFI. Including:

- Creating Unified Kernel Images as described
 [here](https://systemd.io/BOOT_LOADER_SPECIFICATION/).
- Creating all the components necessary for Secure Boot.
- Signing the Unified Kernel Image to boot under Secure Boot.

# Unified Kernel Images

Unified Kernel Images, according to the documentation is:

> A unified kernel image is a single EFI PE executable combining an
> EFI stub loader, a kernel image, an initramfs image, and the kernel command line.

So basically a big file with all the components necessary for booting
directly from UEFI instead of relying on a bootloader. Easier for
signing.

## Installing

The first step is installing the packages necessary to perform all the
steps necessary to have a working Unified Kernel Image.

For this we are using [Alpine Linux](https://alpinelinux.org/) since
it's what I use (Change the commands to equivalents of your distribution).

We need to install the `binutils` package which provides the `objcopy`
binary and `gummiboot` which provides the EFI stub loader in
`/usr/lib/gummiboot/linuxx64.efi.stub`.

Both are in the main repository, so installing them is a matter of just
calling `apk` with the proper commands:

```sh
# apk add binutils gummiboot
```

## Unifying

With all the packages installed we can make the Unified Kernel Image.

### CPU Microcode

One of the components of the Unified Kernel Image is the initramfs. On
other bootloaders you can just specify more than initramfs, having the
CPU microcode coming before the actual initramfs.

Not so much with the Unified Kernel Image. For that we will have to
create a single initramfs that includes the CPU microcode.

```sh
$ cat /boot/intel-ucode.img /boot/initramfs-lts > /tmp/initramfs-lts
```

Simply enough, that will work. Remember to change the intel-ucode for
whatever AMD uses or to ignore this section altogether if you don't
need it.

### objcopying

Now that we have our initramfs with the microcode we can use `objcopy`
to create the image. We will have 4 sections:

- .osrel, where the contents of `/etc/os-release` are present (some
 distributions have it in `/usr/lib/os-release`, but not Alpine Linux)
- .cmdline, where the options passed to the command line of the kernel
 are present, we will use `/proc/cmdline` to get from our currently
 running kernel, but you can write your own into a file and use it
 instead.
- .linux, the kernel itself goes here.
- .initrd, the initramfs itself goes here.

We will use the EFI stub loader from `gummiboot` which is present in
`/usr/lib/gummiboot/linuxx64.efi.stub` and the Unified Kernel Image
will be written to `/boot` as `alpine.efi`.

The `objcopy` invocation goes like so:

```sh
objcopy \
	--add-section .osrel="/etc/os-release" --change-section-vma .osrel=0x20000 \
	--add-section .cmdline="/proc/cmdline" --change-section-vma .cmdline=0x30000 \
	--add-section .linux="/boot/linux-lts" --change-section-vma .linux=0x40000 \
	--add-section .initrd="/tmp/unified-initramfs" --change-section-vma .initrd=0x3000000 \
	/usr/lib/gummiboot/linuxx64.efi.stub /boot/alpine.efi
```

And we have a functional Unified Kernel Image.

```sh
$ file /boot/alpine.efi
/boot/alpine.efi: PE32+ executable (EFI application) x86-64 (stripped to external PDB), for MS Windows
```

# Secure Boot

One of the things I wanted to do when re-creating my boot scheme by
using `sd-boot` was to have Secure Boot enabled. Just for challenging
myself into new territory.

[Arch Linux Wiki](https://wiki.archlinux.org/index.php/Secure_Boot) has
a full page on it, and they point to an extensive article on Secure
Boot. I won't waste anytime trying to explain Secure Boot, the article
referred from the Arch Linux Wiki is written by someone that is much more
qualified to write about it than me. (That is your call to give it a read
if you are interested, I'll wait)

In my approach I made my own keys, which seemed easier than using Shim or
PreLoader.

## Installing

First we install the components necessary, we will need `efitools`. It is
available only in `edge` because it was in the `testing` repository.
I have moved it to main so it should make it to 3.12 but not 3.11 and
below. So enable the testing repository and install it.

We will also use the `sbsign` binary from the `sbsigntool` package.
It has the same situation as `efitools`, was in testing, moved to
main, should be available in Alpine Linux 3.12 but not 3.11 and below.

In the meantime we will also use `uuidgen` from the `util-linux`
package, so if you didn't have that package installed already, do it.

```sh
# apk add efitools sbsigntool util-linux
```

You will also need the `openssl` command from the `openssl` package (
or `libressl` if your Alpine Linux version uses that). But since that
is a system package that is very widely used, I will assume you already
have it.

The following are literally copied from the Arch Linux Wiki.

```sh
$ uuidgen --random > GUID.txt
$ openssl req -newkey rsa:4096 -nodes -keyout PK.key -new -x509 -sha256 -days 3650 -subj "/CN=my Platform Key/" -out PK.crt
$ openssl x509 -outform DER -in PK.crt -out PK.cer
$ cert-to-efi-sig-list -g "$(< GUID.txt)" PK.crt PK.esl
$ sign-efi-sig-list -g "$(< GUID.txt)" -k PK.key -c PK.crt PK PK.esl PK.auth
$ sign-efi-sig-list -g "$(< GUID.txt)" -c PK.crt -k PK.key PK /dev/null rm_PK.auth
$ openssl req -newkey rsa:4096 -nodes -keyout KEK.key -new -x509 -sha256 -days 3650 -subj "/CN=my Key Exchange Key/" -out KEK.crt
$ openssl x509 -outform DER -in KEK.crt -out KEK.cer
$ cert-to-efi-sig-list -g "$(< GUID.txt)" KEK.crt KEK.esl
$ sign-efi-sig-list -g "$(< GUID.txt)" -k PK.key -c PK.crt KEK KEK.esl KEK.auth

$ openssl req -newkey rsa:4096 -nodes -keyout db.key -new -x509 -sha256 -days 3650 -subj "/CN=my Signature Database key/" -out db.crt
$ openssl x509 -outform DER -in db.crt -out db.cer
$ cert-to-efi-sig-list -g "$(< GUID.txt)" db.crt db.esl
$ sign-efi-sig-list -g "$(< GUID.txt)" -k KEK.key -c KEK.crt db db.esl db.auth
```

## Enrolling

Now that the keys were made we need to add them to the Motherboard. As
of writing this I'm using a Dell Inspiron 5566. The Dell firmware is really
really nice and allows me to do all the required operations by just clicking
around their interface.

That means you will have to figure your way in your motherboard's firmware.

First copy the required files to the FAT boot partition that the motherboard
can see.

```sh
# cp *.cer *.esl *.auth /boot
```

Then reboot into your motherboard's firmware and enroll them. You can remove
the files afterward.

```sh
# rm -f /boot/*.cer /boot/*.esl /boot/*.auth
```

## Signing

Now that our keys are enrolled we can sign our Unified Kernel Image:

```sh
$ sbsign --key db.key --cert db.crt --output /boot/alpine.efi /boot/alpine.efi
```

# Booting

The last step is creating an UEFI boot entry, stored normally in NVRAM
as UEFI config variables with boot configuration along them.

## Installing

To deal with UEFI config variables in Linux we need the `mount`
command which is part of the `busybox` package, it will be
replaced with the `mount` command from the `util-linux` package
if the latter is installed, but both are OK.

To manipulate the UEFI config variables we will use the
`efibootmgr` command from the `efibootmgr` package. It is in
the community repository.

```sh
# apk add efibootmgr
```

## Mounting

First we need to mount the UEFI config variables with the efivarfs
filesystem. According to the
[kernel documentation](https://www.kernel.org/doc/Documentation/filesystems/efivarfs.txt)
it can be done like this:

```sh
# mount -t efivarfs none /sys/firmware/efi/efivars
```

## Configuring

Now we create the boot entry with `efibootmgr`. I'll show the final
invocation of `efibootmgr` first and explain each switch/flag used
separately below it.

```sh
# efibootmgr \
	--create \
	--disk /dev/sda \
	--part 1 \
	--label "Alpine Linux" \
	--loader "\alpine.efi"
```

So:

- The `--create` call should be obvious, we want to create the boot
 entry, with it we also add it to the boot order, if you do not wish
 to add to it to the boot order then `--create-only` can be used.
- `--disk /dev/sda` points to the disk where the EFI partition is, if
 your EFI partition is in another disk then change it appropriately.
- `--part 1` is the number of the partition, since my EFI partition is
 in /dev/sda1 then this is 1, but if your partition is in /dev/sda5 then
 it is 5.
- `--label "Alpine Linux"` label used, this will appear in the Motherboard
 Firmware for editing and when you press F12 (or whatever F-Key) to pick
 a different boot option. If you use another distribution then change it
 to it.
- `--loader "\alpine.efi"` the location of the Unified Kernel Image, in
 relation to the EFI partition, since we used /boot/alpine.efi then we
 set it to \alpine.efi (NOTE: the backslash is how it should be, this is
 Windows stuff).

After calling the invocation you can use `efibootmgr` to see if was added
properly.

```sh
$ efibootmgr
BootCurrent: 0000
Timeout: 0 seconds
BootOrder: 0000
Boot0000* Alpine Linux
```

This is my system, I have executed the order 66 on all other boot options,
your should still have the other options like "Windows Boot Manager". The
important thing here is that the "Alpine Linux" entry appears.

If you wish to have it default to booting Alpine Linux then have it be
the first boot entry that appears in BootOrder.
