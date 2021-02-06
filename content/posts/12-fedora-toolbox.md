---
title: "Fedora Toolbox with custom container images"
date: 2021-02-06T10:59:41+01:00
draft: false
---

Recently I've been using Fedora Toolbox a lot for development to have a reproducible
development enviroment across my different systems. To make it easier to have the
same container on multiple machines I've created my own Dockerfile:

```
FROM registry.fedoraproject.org/fedora:33

# Install extra packages
COPY extra-packages /
RUN dnf -y install $(<extra-packages)
RUN rm /extra-packages
```

It basically just uses the base image that's used for toolbox by default and installs
packages that are in the `extra-packages` file. Of course you can also add more things,
e.g. building other packages from source and so on. The `extra-packages` has one extra package
that should be installed per line, like this:

```
fish
clang
```

We can build the image by having the following folder structure:

```
$ ls
Dockerfile extra-packages
```

And issuing the following podman command:

```
podman build . -t $USER/fedora-toolbox:latest
```

Afterwards the toolbox with the custom image can be created with:

```
toolbox create -c fedora-toolbox-33 -i $USER/fedora-toolbox
```

And voilà, you can enter the new toolbox with `toolbox enter`! :)

## Hooking it up with VSCode

Since I'm using the VSCode flatpak I have to use the VSCode Remote extension to
access my Toolbox container. To do that we have to install a SSH server into our container.
We can do that by adding the following lines to our Dockerfile:

```
RUN printf "Port 2222\nListenAddress localhost\nPermitEmptyPasswords yes\n" >> /etc/ssh/sshd_config \
	&& /usr/libexec/openssh/sshd-keygen rsa \
	&& /usr/libexec/openssh/sshd-keygen ecdsa \
	&& /usr/libexec/openssh/sshd-keygen ed25519
```

We can start the SSH server on login by adding the following systemd service file to
`$HOME/.config/systemd/user/toolbox_ssh.service`:

```
[Unit]
Description=Launch sshd in Fedora Toolbox

[Service]
Type=longrun
ExecPre=/usr/bin/podman start fedora-toolbox-33
ExecStart=/usr/bin/toolbox run sudo /usr/sbin/sshd -D

[Install]
WantedBy=multi-user.target
```

Afterwards we can enable & start the service with:

```
systemctl --user daemon-reload
systemctl --user enable --now toolbox_sshd
```

We should also add an entry to our SSH client config to make SSH'ing in the container easier:

```
Host toolbox
	HostName localhost
	Port 2222
	StrictHostKeyChecking no
	UserKnownHostsFile=/dev/null
```

We have to disable `StrictHostKeyChecking` and `UserKnownHostsFile` since the host key
of the container will change every time we regenerate the container.

Afterwards we can SSH into our container by installing the `Remote - SSH` extension
in VSCode:

![VSCode Screenshot](/posts/12-fedora-toolbox-vscode.png)

