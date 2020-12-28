---
title: "Creating an Alpine Developer Environment for Fedora Silverblue"
date: 2020-12-27T21:57:24-03:00
draft: false
---

> Article by editor Leo <thinkabit.ukim@gmail.com>

As readers know I'm a developer for [Alpine Linux][1], it is a very nice simple distribution for running containers.

Unforunately it is not very nice when using GNOME, it has less developers than other distros and its integration isn't as good as it is in the more popular distros like Debian and Fedora.

With that in mind I have decided to test [Fedora Silverblue][2], a flavour of Fedora with GNOME that uses [OSTree][3] to provide reliable upgrades and rollbacks of the operating system, allowing the user to overlay their own packages on top and using container technologies (like [podman][4] and [toolbox][5]) to provide an alternative to installing packages onto the system itself.

In this article I'll describe the process of creating an [Alpine Linux][1] image to be used in podman and accessed via SSH or `podman exec`, while taking into account the peculirarities of working from inside toolbox.

<!--more-->

## Dockerfile

The first thing we need is the image itself, so lets write a `Dockerfile` that has:

- `alpine-sdk` (equivalent to `build-essentials`), `alpine-conf`, `abuild`, `sudo` and `openssh-server`
- `fish` (because I like a nice interactive shell)
- It must have a SSH Daemon configuration that exposes a port for us to use
- Has Hostkeys generated

```dockerfile
FROM alpine:edge
MAINTAINER Leo <thinkabit.ukim@gmail.com>

RUN rm /etc/apk/repositories \
    && printf -- >> /etc/apk/repositories \
    'http://dl-cdn.alpinelinux.org/alpine/edge/%s\n' \
    main community testing

RUN apk add -U --no-cache \
    alpine-conf \
    alpine-sdk \
    abuild \
    sudo \
    openssh-server \
    fish
RUN apk upgrade -a
RUN setup-apkcache /var/cache/apk

RUN /usr/bin/ssh-keygen -A
RUN printf "Port %%PORT%%\nListenAddress localhost\n" >> /etc/ssh/sshd_config

USER root

CMD ["/usr/sbin/sshd", "-D"]
```

Slightly daunting, lets break it down into simpler pieces and explain them one-by-one.

---

```Dockerfile
FROM alpine:edge
MAINTAINER Leo <thinkabit.ukim@gmail.com>
```

Use the `edge` image from Alpine Linux and set myself as maintainer.

```Dockerfile
RUN rm /etc/apk/repositories \
    && printf -- >> /etc/apk/repositories \
    'http://dl-cdn.alpinelinux.org/alpine/edge/%s\n' \
    main community testing
```

Delete previous configuration and enable `main`, `community` and `testing` repositories from edge.

```Dockerfile
RUN apk add -U --no-cache \
    alpine-conf \
    alpine-sdk \
    abuild \
    sudo \
    openssh-server \
    fish
RUN apk upgrade -a
RUN setup-apkcache /var/cache/apk
```

Install the packages mentioned above, then run an upgrade and finally set up a cache for apk so it doesn't need to download the same package multiple times in different `apk` invocations.

```Dockerfile
RUN /usr/bin/ssh-keygen -A
RUN printf "Port %%PORT%%\nListenAddress localhost\n" >> /etc/ssh/sshd_config
```

First generate the hostkeys for the SSH Daemon, and then write some simple configuration options we need.

`Port` is a placeholder value that can be replaced on-the-fly, `ListenAddress` sets what host `sshd` will listen on.

```Dockerfile
USER root

CMD ["/usr/sbin/sshd", "-D"]
```

Force ourselves to run as `root` because the SSH Daemon requires it and set the default startup command to start the SSH Daemon.

## Systemd service

Now that we are done with the image to be run in podman, let's make use of systemd to manage the podman container for us.

```ini
[Unit]
Description=Podman container-alpine-dev-env-for-%u.service

[Service]
Environment=PODMAN_SYSTEMD_UNIT=%n
Restart=on-failure
ExecStartPre=/usr/bin/rm -f %t/alpine-dev-env-for-%u.pid %t/alpine-dev-env-for-%u.ctr-id
ExecStart=%%PODMAN%% run \
    --replace \
    --conmon-pidfile %t/alpine-dev-env-for-%u.pid \
    --cidfile %t/alpine-dev-env-for-%u.ctr-id \
    --publish %%PORT%%:%%PORT%% \
    --volume %h:%h \
    --security-opt label=disable \
    --userns=keep-id \
    --tty \
    --name alpine-dev-env-for-%u \
    --detach \
    alpine-dev-env
# Add our user to abuild group, we require it to access the distfiless
ExecStartPost=%%PODMAN%% exec \
    alpine-dev-env-for-%u \
    adduser %u abuild
# Allow our user to run sudo without any problems
ExecStartPost=%%PODMAN%% exec \
    alpine-dev-env-for-%u \
    sh -c "echo '%u ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/%u-all-nopasswd"
# Add local repos
ExecStartPost=%%PODMAN%% exec \
    alpine-dev-env-for-%u \
    sh -c "printf -- >> /etc/apk/repositories '%h/packages/%%s\n' main community testing"
ExecStop=%%PODMAN%% stop \
    --time 2 \
    --cidfile %t/alpine-dev-env-for-%u.ctr-id
ExecStopPost=%%PODMAN%% rm \
    --ignore \
    --force \
    --cidfile %t/alpine-dev-env-for-%u.ctr-id
PIDFile=%t/alpine-dev-env-for-%u.pid
KillMode=none
Type=forking

[Install]
WantedBy=multi-user.target
```

That is kinda big, lets break it down.

---

```ini
[Unit]
Description=Podman container-alpine-dev-env-for-%u.service
```

Fairly simple, the description for our services, the `%u` is a systemd specifier that is replaced with the user running it.

```ini
[Service]
Environment=PODMAN_SYSTEMD_UNIT=%n
Restart=on-failure
ExecStartPre=/usr/bin/rm -f %t/alpine-dev-env-for-%u.pid %t/alpine-dev-env-for-%u.ctr-id
```

Things that are happening here:

- Set PODMAN_SYSTEMD_UNIT=%n, `%n` is a systemd specifier that is replaced with the full name of the service
- Make the service only restart when it wasn't brought down by a signal or with a clean exit code.
- Before running the service itself, remove some files, the `%t` systemd specifier is replaced with the runtime directory root

```ini
ExecStart=%%PODMAN%% run \
    --replace \
    --conmon-pidfile %t/alpine-dev-env-for-%u.pid \
    --cidfile %t/alpine-dev-env-for-%u.ctr-id \
    --publish %%PORT%%:%%PORT%% \
    --volume %h:%h \
    --security-opt label=disable \
    --userns=keep-id \
    --tty \
    --name alpine-dev-env-for-%u \
    --detach \
    alpine-dev-env
```

Let's go line-by-line.

1. `%%PODMAN%%` will be replaced with the absolute path to the podman binary, `run` is the command to start a container
2. `--replace` means if the container is running we bring it down and start ours, default is to fail if it is already running
3. `--conmon-pidfile` is the path to where the PID of `conmon` will be written
4. `--cidfile` is the path to where the ID of the container will be written
5. `--publish` will expose a port from the container into our host, in this case the port we expose is decided by the user when generating the service
6. `--volume` uses the `%h` (home directory) systemd specifier to mount the host home into the container
7. `--security-opt label=disable` because you can't mount above unless you disable SELinux labels in the container
8. `--userns=keep-id` use the container namespace but keep our ID, if you run this as user 1000 then user 1000 will be avialble in the container
9. `--tty`, request a tty, so our SSH experience won't be miserable
10. `--name` a simple name for the container, so it won't assign a random one
11. `--detach`, don't run in the foreground
12. `alpine-dev-env`, name of the image

```ini
# Add our user to abuild group, we require it to access the distfiless
ExecStartPost=%%PODMAN%% exec \
    alpine-dev-env-for-%u \
    adduser %u abuild
# Allow our user to run sudo without any problems
ExecStartPost=%%PODMAN%% exec \
    alpine-dev-env-for-%u \
    sh -c "echo '%u ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/%u-all-nopasswd"
# Add local repos
ExecStartPost=%%PODMAN%% exec \
    alpine-dev-env-for-%u \
    sh -c "printf -- >> /etc/apk/repositories '%h/packages/%%s\n' main community testing"
```

Someone already commented so lets go to the next one.

```ini
ExecStop=%%PODMAN%% stop \
    --time 2 \
    --cidfile %t/alpine-dev-env-for-%u.ctr-id
ExecStopPost=%%PODMAN%% rm \
    --ignore \
    --force \
    --cidfile %t/alpine-dev-env-for-%u.ctr-id
```

When stopping, wait 2 seconds before we force our way in, after stopping the service, delete the container forcefully.

```ini
PIDFile=%t/alpine-dev-env-for-%u.pid
KillMode=none
Type=forking

[Install]
WantedBy=multi-user.target
```

- `PIDFile` uses the one created by `podman run` in `ExecStart`
- `KillMode` is set to `none` because we bring down a container, not a service
- `Type` is `forking` because we make podman `--detach` itself into the background

## abuild

We now need a wrapper for running abuild commands, it needs to perform certain actions before we run in the container.

```sh
#!/bin/sh
die() {
    printf "%s\\n" "$@" >&2
    exit 1
}

run() {
    ssh -p %%PORT%% -tt \
        -o User=$USER \
        -o IdentityFile=~/.ssh/alpine-dev-env \
        -o NoHostAuthenticationForLocalhost=yes \
        -o LogLevel=QUIET \
        localhost "$@"
}

: ${APORTSDIR:=%%APORTSDIR%%}

APORTSDIRNAME="$(basename $APORTSDIR)"

## check running from within an `aports` tree
if [ "${PWD%*/$APORTSDIRNAME/*}" = "$PWD" ]; then
    die "Error: expecting to be run from within an aports tree!" \
        "It must be run under '$APORTSDIR'"
fi

# Generate new abuild key if not set
cmd="grep -sq '^PACKAGER_PRIVKEY=' $HOME/.abuild/abuild.conf || abuild-keygen -n -a"

# Copy keys over, we need this so packages will actually succeed when
# building (because of the signing stage), this is also required to
# install them
cmd="$cmd && sudo cp $HOME/.abuild/*.rsa.pub /etc/apk/keys"

case "$1" in
    checksum|unpack) cmd="$cmd; cd $APORTSDIR/${PWD#*/$APORTSDIRNAME/} && abuild $@" ;;
    *) cmd="$cmd && cd $APORTSDIR/${PWD#*/$APORTSDIRNAME/} && sudo apk upgrade -U -a && abuild $@" ;;
esac

if ! systemctl --user is-active --quiet alpine-ssh.service; then
    die "alpine-ssh.service must be active, run systemctl --user start alpine-ssh.service"
fi

run "$cmd"
```

Notice a few things:

- We run `apk upgrade -U -a` for any command other than `checksum` and `unpack`, the latter don't build anything and won't get maluses from having an outdated system.
- We use systemd to tell us if we are running the service

## Makefile

To bring it all together and provide a nice workflow for building the image and installing the files lets write a makefile.

```Makefile
PORT ?= 2223
PODMAN ?= $(shell command -v podman)
PODMAN_BUILD ?= $(shell command -v podman)
SSH_KEYGEN ?= $(shell command -v ssh-keygen)
HOME ?= $(shell echo $$HOME)
APORTSDIR ?= $(shell echo $$APORTSDIR)
BINDIR ?= $(HOME)/bin

.DEFAULT_GOAL := install

sanity: sanity-podman \
		sanity-podman-build \
		sanity-aportsdir \
		sanity-ssh-keygen \
		sanity-home

sanity-podman:
ifeq ($(strip $(PODMAN)),)
	$(error podman to run in the systemd system service could not be found, set it with PODMAN=)
endif

sanity-podman-build:
ifeq ($(strip $(PODMAN_BUILD)),)
	$(error podman used to build the image could not be found, set it with PODMAN_BUILD=)
endif

sanity-aportsdir:
ifeq ($(strip $(APORTSDIR)),)
	$(error APORTSDIR is not set, must be absolute path to aports)
endif

sanity-ssh-keygen:
ifeq ($(strip $(SSH_KEYGEN)),)
	$(error ssh-keygen not installed, pass path to ssh-keygen binary via SSH_KEYGEN=)
endif

sanity-home:
ifeq ($(strip $(HOME)),)
    $(error HOME is not set, it must be set to the home directory)
endif

abuild: abuild.in
	sed -e 's|%%PORT%%|$(PORT)|g' \
		-e 's|%%APORTSDIR%%|$(APORTSDIR)|g' \
		abuild.in >| abuild
	chmod +x abuild

keygen: sanity-ssh-keygen sanity-home
	@if [ ! -f $(HOME)/.ssh/alpine-dev-env ] || [ ! -f $(HOME)/.ssh/alpine-dev-env.pub ]; then \
		echo y | $(SSH_KEYGEN) -t ed25519 -f $(HOME)/.ssh/alpine-dev-env -q -N ""; \
	fi
	@if [ ! -f $(HOME)/.ssh/authorized_keys ]; then \
		cat $(HOME)/.ssh/alpine-dev-env.pub >> $(HOME)/.ssh/authorized_keys; \
	elif ! grep -q "$$(cat $(HOME)/.ssh/alpine-dev-env.pub)" $(HOME)/.ssh/authorized_keys; then \
		cat $(HOME)/.ssh/alpine-dev-env.pub >> $(HOME)/.ssh/authorized_keys; \
	fi

systemd: sanity-podman alpine-ssh.service.in
	sed -e 's|%%PORT%%|$(PORT)|g' \
		-e 's|%%PODMAN%%|$(PODMAN)|g' \
		alpine-ssh.service.in >| alpine-ssh.service

dockerfile: Dockerfile.in
	sed	-e 's|%%PORT%%|$(PORT)|g' \
		Dockerfile.in >| Dockerfile

image: sanity-podman-build
	$(PODMAN_BUILD) build -t alpine-dev-env .

install: sanity abuild keygen systemd dockerfile image
	install -Dm0755 abuild -t $(BINDIR)
	install -Dm0644 alpine-ssh.service -t $(HOME)/.config/systemd/user
```

Even if it was one line, makefile would still warrant an explanation.

---

```Makefile
PORT ?= 2223
PODMAN ?= $(shell command -v podman)
PODMAN_BUILD ?= $(shell command -v podman)
SSH_KEYGEN ?= $(shell command -v ssh-keygen)
HOME ?= $(shell echo $$HOME)
APORTSDIR ?= $(shell echo $$APORTSDIR)
BINDIR ?= $(HOME)/bin

.DEFAULT_GOAL := install
```

Set some variables we will use later, all of them can be overriden if desired.

Notice how we split `PODMAN` and `PODMAN_BUILD`, only the latter is actually ran on the system.

Also make `install` the goal, if you just type `make` it will run that target.

```Makefile
sanity: sanity-podman \
		sanity-podman-build \
		sanity-aportsdir \
		sanity-ssh-keygen \
		sanity-home

sanity-podman:
ifeq ($(strip $(PODMAN)),)
	$(error podman to run in the systemd system service could not be found, set it with PODMAN=)
endif

sanity-podman-build:
ifeq ($(strip $(PODMAN_BUILD)),)
	$(error podman used to build the image could not be found, set it with PODMAN_BUILD=)
endif

sanity-aportsdir:
ifeq ($(strip $(APORTSDIR)),)
	$(error APORTSDIR is not set, must be absolute path to aports)
endif

sanity-ssh-keygen:
ifeq ($(strip $(SSH_KEYGEN)),)
	$(error ssh-keygen not installed, pass path to ssh-keygen binary via SSH_KEYGEN=)
endif

sanity-home:
ifeq ($(strip $(HOME)),)
    $(error HOME is not set, it must be set to the home directory)
endif
```

Simple enough, define some targets that will check the sanity of values, we don't want to fail with some weird error because one of our values isn't set to at least something.

If the user sets it to something stupid then it is the user's fault.

```Makefile
abuild: abuild.in
	sed -e 's|%%PORT%%|$(PORT)|g' \
		-e 's|%%APORTSDIR%%|$(APORTSDIR)|g' \
		abuild.in >| abuild
	chmod +x abuild
```

Now the placeholders make sense, we replace them with the almighty `sed` and write them to a final file.

```Makefile
keygen: sanity-ssh-keygen sanity-home
	@if [ ! -f $(HOME)/.ssh/alpine-dev-env ] || [ ! -f $(HOME)/.ssh/alpine-dev-env.pub ]; then \
		echo y | $(SSH_KEYGEN) -t ed25519 -f $(HOME)/.ssh/alpine-dev-env -q -N ""; \
	fi
	@if [ ! -f $(HOME)/.ssh/authorized_keys ]; then \
		cat $(HOME)/.ssh/alpine-dev-env.pub >> $(HOME)/.ssh/authorized_keys; \
	elif ! grep -q "$$(cat $(HOME)/.ssh/alpine-dev-env.pub)" $(HOME)/.ssh/authorized_keys; then \
		cat $(HOME)/.ssh/alpine-dev-env.pub >> $(HOME)/.ssh/authorized_keys; \
	fi
```

Here we generate a key called `alpine-dev-env` and write it to our `authorized_keys`, it does a lot of hoop-dancing to do it without messing with prior user configuration.

```Makefile
systemd: sanity-podman alpine-ssh.service.in
	sed -e 's|%%PORT%%|$(PORT)|g' \
		-e 's|%%PODMAN%%|$(PODMAN)|g' \
		alpine-ssh.service.in >| alpine-ssh.service

dockerfile: Dockerfile.in
	sed	-e 's|%%PORT%%|$(PORT)|g' \
		Dockerfile.in >| Dockerfile
```

Simple enough, just replacing placeholders with `sed` and writing them out for later use.

```Makefile
image: sanity-podman-build
	$(PODMAN_BUILD) build -t alpine-dev-env .

install: sanity abuild keygen systemd dockerfile image
	install -Dm0755 abuild -t $(BINDIR)
	install -Dm0644 alpine-ssh.service -t $(HOME)/.config/systemd/user
```

Here we use `PODMAN_BUILD` to build the image and in the install we install the systemd service and the abuild wrapper.

## Building it

Lets run it ourselves!

```txt
$ make PODMAN=/usr/bin/podman PODMAN_BUILD="flatpak-spawn --host podman" APORTSDIR=$HOME/Repositories/aports
sed -e 's|%%PORT%%|2223|g' \
	-e 's|%%APORTSDIR%%|/var/home/mx/Repositories/aports|g' \
	abuild.in >| abuild
chmod +x abuild
sed -e 's|%%PORT%%|2223|g' \
	-e 's|%%PODMAN%%|/usr/bin/podman|g' \
	alpine-ssh.service.in >| alpine-ssh.service
sed	-e 's|%%PORT%%|2223|g' \
	Dockerfile.in >| Dockerfile
flatpak-spawn --host podman build -t alpine-dev-env .
STEP 1: FROM alpine:edge
STEP 2: MAINTAINER Leo <thinkabit.ukim@gmail.com>
--> 778bf6c70a3
STEP 3: RUN rm /etc/apk/repositories     && printf -- >> /etc/apk/repositories     'http://dl-cdn.alpinelinux.org/alpine/edge/%s\n'     main community testing
--> 5feeea8c404
STEP 4: RUN apk add -U --no-cache     alpine-conf     alpine-sdk     abuild     sudo     openssh-server     fish
fetch http://dl-cdn.alpinelinux.org/alpine/edge/main/x86_64/APKINDEX.tar.gz
fetch http://dl-cdn.alpinelinux.org/alpine/edge/community/x86_64/APKINDEX.tar.gz
fetch http://dl-cdn.alpinelinux.org/alpine/edge/testing/x86_64/APKINDEX.tar.gz
(1/51) Installing fakeroot (1.25.3-r3)
(2/51) Installing openssl (1.1.1i-r0)
(3/51) Installing libattr (2.4.48-r0)
(4/51) Installing attr (2.4.48-r0)
(5/51) Installing libacl (2.2.53-r0)
(6/51) Installing tar (1.32-r1)
(7/51) Installing pkgconf (1.7.3-r0)
(8/51) Installing patch (2.7.6-r6)
(9/51) Installing libgcc (10.2.1_pre1-r1)
(10/51) Installing libstdc++ (10.2.1_pre1-r1)
(11/51) Installing lzip (1.21-r0)
(12/51) Installing ca-certificates (20191127-r5)
(13/51) Installing brotli-libs (1.0.9-r2)
(14/51) Installing nghttp2-libs (1.42.0-r0)
(15/51) Installing libcurl (7.74.0-r0)
(16/51) Installing curl (7.74.0-r0)
(17/51) Installing abuild (3.7.0_rc1-r2)
Executing abuild-3.7.0_rc1-r2.pre-install
(18/51) Installing ifupdown-ng (0.10.2-r1)
(19/51) Installing openrc (0.42.1-r17)
Executing openrc-0.42.1-r17.post-install
(20/51) Installing alpine-conf (3.9.0-r1)
(21/51) Installing binutils (2.35.1-r1)
(22/51) Installing libmagic (5.39-r0)
(23/51) Installing file (5.39-r0)
(24/51) Installing libgomp (10.2.1_pre1-r1)
(25/51) Installing libatomic (10.2.1_pre1-r1)
(26/51) Installing libgphobos (10.2.1_pre1-r1)
(27/51) Installing gmp (6.2.1-r0)
(28/51) Installing isl22 (0.22-r0)
(29/51) Installing mpfr4 (4.1.0-r0)
(30/51) Installing mpc1 (1.2.0-r0)
(31/51) Installing gcc (10.2.1_pre1-r1)
(32/51) Installing musl-dev (1.2.2_pre6-r0)
(33/51) Installing libc-dev (0.7.2-r3)
(34/51) Installing g++ (10.2.1_pre1-r1)
(35/51) Installing make (4.3-r0)
(36/51) Installing fortify-headers (1.1-r0)
(37/51) Installing build-base (0.5-r2)
(38/51) Installing expat (2.2.10-r0)
(39/51) Installing pcre2 (10.36-r0)
(40/51) Installing git (2.29.2-r0)
(41/51) Installing alpine-sdk (1.0-r0)
(42/51) Installing ncurses-terminfo-base (6.2_p20201219-r0)
(43/51) Installing ncurses-libs (6.2_p20201219-r0)
(44/51) Installing readline (8.0.4-r0)
(45/51) Installing bc (1.07.1-r1)
(46/51) Installing libpcre2-32 (10.36-r0)
(47/51) Installing fish (3.1.2-r2)
Executing fish-3.1.2-r2.post-install
(48/51) Installing openssh-keygen (8.4_p1-r2)
(49/51) Installing openssh-server-common (8.4_p1-r2)
(50/51) Installing openssh-server (8.4_p1-r2)
(51/51) Installing sudo (1.9.4p2-r0)
Executing busybox-1.32.0-r8.trigger
Executing ca-certificates-20191127-r5.trigger
OK: 227 MiB in 65 packages
--> 32cf4ad3bc5
STEP 5: RUN apk upgrade -a
fetch http://dl-cdn.alpinelinux.org/alpine/edge/main/x86_64/APKINDEX.tar.gz
fetch http://dl-cdn.alpinelinux.org/alpine/edge/community/x86_64/APKINDEX.tar.gz
fetch http://dl-cdn.alpinelinux.org/alpine/edge/testing/x86_64/APKINDEX.tar.gz
(1/1) Upgrading scanelf (1.2.6-r1 -> 1.2.8-r0)
Executing busybox-1.32.0-r8.trigger
OK: 227 MiB in 65 packages
--> e2912f31f70
STEP 6: RUN setup-apkcache /var/cache/apk
--> ca2d3c87fa7
STEP 7: RUN /usr/bin/ssh-keygen -A
ssh-keygen: generating new host keys: RSA DSA ECDSA ED25519 
--> 9acb5894b83
STEP 8: RUN printf "Port 2223\nListenAddress localhost\n" >> /etc/ssh/sshd_config
--> 597d6599e84
STEP 9: USER root
--> 6eb7556707f
STEP 10: CMD ["/usr/sbin/sshd", "-D"]
STEP 11: COMMIT alpine-dev-env
--> 40e2133df8e
40e2133df8efa540d5a0eb0b67c6e3c0f5a02d7bd00dfca662b298a331c20a59
install -Dm0755 abuild -t /var/home/mx/bin
install -Dm0644 alpine-ssh.service -t /var/home/mx/.config/systemd/user
```

Now let's run it!

```txt
$ systemctl --user daemon-reload
$ systemctl --user start alpine-ssh.service
$ systemctl --user status alpine-ssh.service
● alpine-ssh.service - Podman container-alpine-dev-env-for-mx.service
     Loaded: loaded (/var/home/mx/.config/systemd/user/alpine-ssh.service; enabled; vendor preset: disabled)
     Active: active (running) since Sun 2020-12-27 23:04:46 -03; 16s ago
    Process: 960938 ExecStartPre=/usr/bin/rm -f /run/user/1000/alpine-dev-env-for-mx.pid /run/user/1000/alpine-dev-env-for-mx.ctr-id (code=exited, status=0/SUCCESS)
    Process: 960939 ExecStart=/usr/bin/podman run --replace --conmon-pidfile /run/user/1000/alpine-dev-env-for-mx.pid --cidfile /run/user/1000/alpine-dev-env-for-mx.ctr-id --publish 2223:2223 --volume /var/home/mx:/var/home/mx --security-opt label=disable --userns=keep-id --tty --name alpine-dev-env-for-mx --detach alpine-dev-env (code=exited, status=0/SUCCESS)
    Process: 960996 ExecStartPost=/usr/bin/podman exec alpine-dev-env-for-mx adduser mx abuild (code=exited, status=0/SUCCESS)
    Process: 961026 ExecStartPost=/usr/bin/podman exec alpine-dev-env-for-mx sh -c echo 'mx ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/mx-all-nopasswd (code=exited, status=0/SUCCESS)
    Process: 961054 ExecStartPost=/usr/bin/podman exec alpine-dev-env-for-mx sh -c printf -- >> /etc/apk/repositories '/var/home/mx/packages/%s
' main community testing (code=exited, status=0/SUCCESS)
   Main PID: 960965 (conmon)
      Tasks: 26 (limit: 18990)
     Memory: 99.3M
        CPU: 1.186s
[truncated]
```

Can we SSH into it ?

![We can SSH into it](/posts/11-ssh.png)

## Future

This is basically done as far as having a developer environment is concerned, all that is left is more improvments to hardening and user experience itself:

- Find a way to not even need a key, just allow the same user to connect with no worries
- If the above is not possible then
  - add `from=` in the `authorized_keys` so only `127.0.0.1` can connect.
  - add `$USER` to the end of our keys in `authorized_keys` so only our user can connect.

[1]: https://alpinelinux.org
[2]: https://silverblue.fedoraproject.org/
[3]: https://ostree.readthedocs.io/en/latest/
[4]: https://podman.io/
[5]: https://docs.fedoraproject.org/en-US/fedora-silverblue/toolbox/
