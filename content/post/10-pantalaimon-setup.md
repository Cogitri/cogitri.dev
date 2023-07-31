---
title: "Setting up Pantalaimon for usage with Matrix clients and using panctl"
date: 2020-11-01T19:39:20-03:00
draft: false
---

> Article by editor Leo <thinkabit.ukim@gmail.com>

[Pantalaimon][1] is a End-to-End Encryption (E2EE) aware proxy daemon that
connects to a [Matrix][2] server and handles sending and receiving messages.
It also handles verifying sessions, verifying or blacklisting devices, and
exporting/importing session keys.

Its main use-case is to provide clients that have not yet fully implemented
some of the most important Matrix's features, namely verifying devices and
End-to-End encryption, a good man-in-the-middle that does it transparently
for you.

Today we will set up a local `pantalaimon` daemon and log in with
[Fractal][3], the GNOME client for Matrix. We will also learn how to use the
`panctl` program from Pantalaimon to verify the session we started with Fractal.

<!--more-->

## Installation

The first step is installing Pantalaimon. It can be installed via `pip` as it
is a python program, but we will instead use our distro repositories, in this
case [Alpine Linux][4].

```prompt
# apk add pantalaimon pantalaimon-ui 
```

We also need to install Fractal, instead of using the distro repositories lets
use the flatpak-ed version from [FlatHub][6]:

```text
$ flatpak install fractal
Looking for matches…
Found similar ref(s) for ‘fractal’ in remote ‘flathub’ (user).
Use this remote? [Y/n]:
Found ref ‘app/org.gnome.Fractal/x86_64/stable’ in remote ‘flathub’ (user).
Use this ref? [Y/n]:
Required runtime for org.gnome.Fractal/x86_64/stable (runtime/org.gnome.Platform/x86_64/3.36) found in remote flathub
Do you want to install it? [Y/n]:

org.gnome.Fractal permissions:
    ipc                  network      pulseaudio      wayland     x11     dri
    dbus access [1]

    [1] org.freedesktop.Notifications, org.freedesktop.secrets


        ID                                  Branch          Op          Remote           Download
 1. [✓] org.gnome.Fractal.Locale            stable          i           flathub            4.8 kB / 233.8 kB
 2. [✓] org.gnome.Platform.Locale           3.36            i           flathub           17.7 kB / 323.1 MB
 3. [✓] org.gnome.Platform                  3.36            i           flathub          172.7 MB / 326.0 MB
 4. [✓] org.gnome.Fractal                   stable          i           flathub            3.5 MB / 3.6 MB

Installation complete.
```

## Configuration

Now that we have Pantalaimon installed we need to create the configuration file,
the location is `${XDG_CONFIG_HOME:-$HOME/.config}/pantalaimon/pantalaimon.conf`.

```ini
[local-matrix]
Homeserver = https://matrix.org
ListenAddress = localhost
ListenPort = 8010
```

The `Homeserver` key holds what is the server you're connecting to.

The `ListenAddress` key decides the URL where the daemon will listen for
connections, in this case we are doing a local server so use localhost.

Finally `ListenPort` decides what port of the URL that pantalaimon is going to
listen in.

## Running

Now we run the daemon and start our client, just invoke the `pantalaimon` binary
and start the flatpak via `flatpak run org.gnome.Fractal`.

### Fractal

When Fractal asks us for our provider instead of using the `Homeserver`, which is
normally expected, we instead put the `ListenAddress` and `ListenPort` from
pantalaimon as shown below:

![Our Provider is Local](/posts/10-provider.png)

## panctl

We now need to verify the Pantalaimon session, in this case we need an already
verified device running that can perform verification, one can safely use the
Element Web on the Desktop or the Mobile application.

We will use the `panctl` binary, which interacts with the running `pantalaimon`
daemon and allows us to verify our session.

### Getting info from panctl

But first lets take a look at what information `panctl` can give to us. It is
very important as we need the the correct ID of the device.

```text
$ panctl
panctl> list-servers
```

```yaml
pantalaimon servers:
 - Name: local-matrix
 - Pan users:
   - @maxice8:matrix.org BFXSMBOBLH
```

We have one server running, the `Name` key holds the value that is present in
our configuration, and the `Pan users` collection holds all the users that are
logged in, in this case we are logged in via fractal and our id is `BFXSMBOBLH`.

```text
panctl> list-devices @maxice8:matrix.org @maxice8:matrix.org
```

```yaml
Devices for user @maxice8:matrix.org:
 - Display name:  FluffyChat android
   - Device id:   UXOXMSYWMH
   - Device key:  [STRENG GEHEIM]
   - Trust state: Verified
 - Display name:  Element Desktop (Linux)
   - Device id:   QPOOTXJLUS
   - Device key:  [STRENG GEHEIM]
   - Trust state: Verified
```

Those are my devices, you can see I use [FlufflyChat][7] on my Android phone
and have Element Desktop on my desktop, we will use the latter to perform
the confirmation.

Important here is to take note of the ID of the device we want to start the
verification with, in this case the ID is `QPOOTXJLUS`.

### Starting verification from panctl

First we call the start-verification program

```text
panctl> start-verification @maxice8:matrix.org @maxice8:matrix.org QPOOTXJLUS
Successfully started the key verification request
```

Then we look at our Element client:

![On Element Web](/posts/10-verification.png)

Click `continue`, and then switch back to `panctl` we need to check if the
emojis match.

![Do They Match?](/posts/10-match.png)

```text
Short authentication string for pan user @maxice8:matrix.org from @maxice8:matrix.org via QPOOTXJLUS:
     🚀          🔑          🍎          🚂          🎸          ⚓          🔧
   Rocket       Key        Apple       Train       Guitar      Anchor      Wrench
```

If they match we can click `They match` in Element and on panctl we need to
confirm-verification:

```text
panctl> confirm-verification @maxice8:matrix.org @maxice8:matrix.org QPOOTXJLUS
Device QPOOTXJLUS of user @maxice8:matrix.org succesfully verified for pan user @maxice8:matrix.org.
```

And in your Element client ?

![Success!](/posts/10-verified.png)

Now, that doesn't mean we are done, we can also import/export the End-to-End
encryption keys to be used in other contexts.

```text
panctl> export-keys @maxice8:matrix.org ~/tmp/ourkeys pass
Succesfully exported keys for @maxice8:matrix.org to /home/enty/tmp/ourkeys
panctl> import-keys @maxice8:matrix.org ~/tmp/ourkeys pass
Succesfully imported keys for @maxice8:matrix.org from /home/enty/tmp/ourkeys
```

[1]: https://github.com/matrix-org/pantalaimon
[2]: https://matrix.org/
[3]: https://wiki.gnome.org/Apps/Fractal
[4]: https://alpinelinux.org
[5]: https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
[6]: https://flathub.org/apps/details/org.gnome.Fractal
[7]: https://fluffychat.im/
