---
title: "Using KeePassXC as your system-keyring and ssh-agent"
date: 2019-11-04T11:33:37-03:00
draft: false
aliases:
    - /posts/03-keepassxc-freedesktop-secret/
    - /post/03-keepassxc-freedesktop-secret/
---

###### Guest article by maxice8

Recently the community-oriented password manager [KeePassXC](https://keepassxc.org/) made a new
major release, 2.5.0.

In this new release there was a really important change, the implementation of the
[secrets API](https://freedesktop.org/wiki/Specifications/secret-storage-spec/secrets-api-0.1.html)
from Freedesktop.

<!--more-->

> This is oversimplified

For those that don't know, the secrets API is a specification for
storing and querying secrets (duh) like passwords, tokens and ssh keys, and really
anything you wanted.

After getting pleasantly surprised that someone else updated the keepassxc package on
Alpine Linux, I decided to enable keepassxc as my system-keyring instead of gnome-keyring

# Setting up within keepassxc

First thing to do is enabling the `Secret Service Integration` on keepassxc itself, this can
be done by clicking on `Tools` in the bar on top, then `Settings` and scrolling down the left bar
and clicking on `Secret Service Integration`. Then tick
`Enable KeepassXC Freedesktop.org Secret Service Integration`.

After enabling the `Secret Service Integration`, you need to change the database settings so
the entries of the database are exposed via the integration.

First click on `Database` on the bar on top then on `Database Settings ...` and then click on
`Secret Service Integration` and tick the option `Expose entries under this group:`, below the
option there is a tree manager so you can pick only a part of the entries of the database to
be exposed.

To make sure it works, have your database unlocked (should already be for changing the setting
above) and use `secret-tool(1)` to query for a secret on your database.

> The key called 'secret' is [REDACTED] for obvious reasons

```ini
$ secret-tool search --unlock Path lichess
[/org/freedesktop/secrets/collection/all/8cbc4c2af67a428a8b7859fdaf25881b]
label = lichess
secret = [REDACTED]
created = 2019-09-06 17:31:10
modified = 2019-10-30 01:18:16
attribute.Title = lichess
attribute.URL = https://lichess.org
attribute.UserName = voidlinux1
attribute.Path = /lichess
attribute.Uuid = 8cbc4c2af67a428a8b7859fdaf25881b
attribute.Notes = 
```

> PS: hit me up on lichess.org if you want to play :D

# Experience thus far 

Replacing my previous system-keyring provider, gnome-keyring, proved to be
overall good but with some very annoying quirks.

Benefits:

- I don't need more shell code to properly initialize gnome-keyring
- I don't need to wrestle around with PAM to properly initialize and unlock the keyring
- The place where I store my secrets in my computer and everywhere else is the same

Drawbacks:

- I can't use my system-keyring to automatically unlock the database on login and unlock
- There is no pop-up dialog like in gnome-keyring to unlock the database when something queries
 for secrets using the freedesktop API

# Integrating with ssh-agent

Speaking of which, since gnome-keyring was gone i needed to re-enable `ssh-agent(1)` so
i can use my precious precious (that i dispose and replace a lot) ssh keys everywhere.

I start `ssh-agent(1)` on my .profile, which is run every time I login with the following
code:

```sh
if ! pgrep -x ssh-agent -u $(id -u) >/dev/null; then
	# This sets SSH_AUTH_SOCK and SSH_AGENT_PID variables
	eval "$(ssh-agent -s)"
	export SSH_AUTH_SOCK SSH_AGENT_PID
	cat > "$XDG_RUNTIME_DIR/ssh-agent-env" <<- __EOF__
	export SSH_AUTH_SOCK=$SSH_AUTH_SOCK
	export SSH_AGENT_PID=$SSH_AGENT_PID
	__EOF__
else
	if [ -s "$XDG_RUNTIME_DIR/ssh-agent-env" ]; then
		. $XDG_RUNTIME_DIR/ssh-agent-env
	fi
fi
```

It checks if there is an `ssh-agent(1)` running under my user, If not then it starts
it and exports `SSH_AUTH_SOCK` which is the path of the socket you can use
to communicate with `ssh-agent(1)`.

It also writes a file called `ssh-agent-env` to my `XDG_RUNTIME_DIR` which is sourced
by any shell that reads .profile (all of the shells started in the console)
so all my sessions can use the same ssh-agent.

`SSH_AUTH_SOCK` is used by keepassxc for ssh-agent integration, having the
variable being set in .profile guarantees that it will be available for keepassxc
to use, since .profile also starts X and keepassxc is started within X.

To enable ssh-agent integration on keepassxc just click on `Tools` in the top bar
then click on `Settings` and then on the left-side click on `SSH Agent` and tick
the box `Enable SSH Agent (requires restart)` and restart (as told 4 to 5 words ago)
keepassxc.

# Adding an SSH key

Adding a ssh-key is very simple, just create a new entry which has its password field
be the password for the key being used, then click on `Advanced` and add the private key
as an attachment.

After adding the SSH key as an attachment, click on `SSH Agent` on the left side and tick
`Add key to agent when database is opened/unlocked` and select the attachment you just
added on the private key section.

You can then copy the public key part to your clipboard and use it wherever you have to
use, like GitHub, GitLab, etc.
