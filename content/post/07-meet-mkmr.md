---
title: "Introducing mkmr, a collection of python3 tools to interact with GitLab"
date: 2020-08-12T18:44:02-03:00
draft: false
---

> Article by editor Leo <thinkabit.ukim@gmail.com>

The Linux distribution I contribute to, [Alpine Linux](https://alpinelinux.org),
has recently switched fully to using GitLab (self-hosted instance) and has started
gradually phasing out support for sending patches via the Mailing List.

To help smooth the transition for Mailing List contributors and also make contributing
to Alpine Linux in general more efficient, I decided to step up and help by making it
easier to create, edit and merge Merge Requests.

<!--more-->

## Introduction

`mkmr` is a collection of tools written in python3 that primarily uses
[python-gitlab](https://github.com/python-gitlab/python-gitlab) to interact with GitLab
instances. While primarily developed for Alpine Linux's GitLab instance it is expected
to work with any GitLab instance.

Although the project is called `mkmr`, it is composed of various commandline tools that
serve different purposes, like `mkmr` (make a merge request), `mgmr` (merge a merge request),
`vimr` (edit attributes of a merge request in a text editor), and `edmr` (edit attributes
of a merge request programmatically).

### Installation

Users of Alpine Linux can install it with `apk add mkmr`, one can also install `mkmr-doc`
to get the manpages which are written in [scdoc](https://git.sr.ht/~sircmpwn/scdoc).

It can also be installed with `pip install mkmr` for other users, although manpages won't
be installed.

### Initial configuration

On first use, any of the binaries provided by `mkmr` it will ask you for your
Personal Access Token. This is required for python-gitlab to authenticate to the GitLab
instance and do actions as your user.

![Asking User for Personal Access Token](/posts/07-meet-mkmr-01.png)

In the repository you wish to contribute to you will need 2 remotes set, one that has
a URL that points to your fork of the repo and one that points to the repo you want to
contribute to. By default they are `origin` and `upstream`.

The remote can be modified depending on the tool. For tools that interact between a fork
and upstream, one can use `--origin=ORIGIN` and `--upstream=UPSTREAM` to set different
remote names. For tools that only interact with upstream one can use `--remote=REMOTE`.

The values can be saved in configuration by using `--save` (save and continue operation
of the requested tool) or `--write` (save and exit). The configuration is written to
`${XDG_CONFIG_HOME:-$HOME/.config}/mkmr/config` and resides in a section named after
the directory the repository resides.

![Example Configuration](/posts/07-meet-mkmr-05.png)

The configuration takes the form of INI files, the section refers to the repo, and stores
configuration for the repository generally, such as `--origin`, `--upstream` and `--remote`.

Each tool also has its own per-repository configuration, `[aports mkmr]` as shown above
denotes configuration for the `mkmr` binary for the `aports` repository.

### mkmr

`mkmr` is the first binary that was written and was the main reason behind starting the
project itself, Mailing List users are used to using git-send-email to send an E-mail to
a Mailing List, while GitLab expect users to create a fork of the repository you want to
contribute to, then push a branch to it and create a merge request asking for the branch
in your fork to be merged into the branch in upstream.

`mkmr` tries to bridge the gap by allowing the user to create the merge request from the
commandline. This is done by automating pushing a new branch to the user's fork and then
creating the merge request via the GitLab API.

`mkmr` will prompt before making the merge request, letting you check if your values are
as expected. This can be skipped by passing `--yes` (and made permanent by passing
`--save` with it).

![Prompting the user](/posts/07-meet-mkmr-02.png)

If one wants to pass a different title, description or labels when creating the merge
request, one can pass `--edit` (can be made permanent with `--save`), which will open
`$EDITOR` with instructions, inspired by `git rebase -i`.

![Editing the attributes](/posts/07-meet-mkmr-03.png)

After checking everything and passing yes to the prompt, the merge request will be created

![Merge Request created](/posts/07-meet-mkmr-04.png)

After creating the merge request, the iid of the merge request will be saved in the cache,
in a file named after the branch of the merge request. This is used by other tools to connect
a branch name to an specific merge request.

```sh
$ tree $XDG_CACHE_HOME/mkmr/gitlab.alpinelinux.org/alpine/aports/branches
/home/enty/var/cache/mkmr/gitlab.alpinelinux.org/alpine/aports/branches
├── 3.11-busybox
├── 3.12-alpine-baselayout
├── 3.12-busybox
├── arc-theme
├── busybox
├── fuse3
├── perl-module-scandeps
├── poppler
├── py3-pytools
├── py3-validators
├── screenfetch
├── strace
├── tumbler
├── vips
└── volumeicon

0 directories, 15 files
```

### mgmr

`mgmr`, the second most important of the `mkmr` tools, handles merging merge requests by
rebasing them until they are matching upstream, then merging them. It works only on FF
merges.

![Mixed args to merge](/posts/07-meet-mkmr-06.png)

It can take lots of merge requests and try to merge them all sequentially, it does it by
creating its own merge train, which attempts to rebase-and-merge each until it succeeds or
it hits an an error it cannot recover from. It then prints out a summary to the user
of what merge requests were merged and if not what was the error message.

It can take the iid of the merge request (the number on the URL one can refer with !N) or
it can take the name of a branch which will be looked up on the cache and matched to an iid.

![Final Report](/posts/07-meet-mkmr-07.png)

After merging, `mgmr` will delete all branches that were merged by usage of the cache.

### vimr

This one allows users to edit attributes of a given merge request by opening them in `$EDITOR`.

> This is the result of: vimr -n 11361

```null
# Set to 'close' to close the merge request
# set to 'reopen' to open a closed merge request
State: opened

# Everything after 'Title: ' is the title of the merge request
Title: community/picard: upgrade to 2.4.1

# Any long multi-line string, will consider everything until the first line
# that starts with a hashtag (#)
Description:

# Whitespace-separated list of labels, have it empty to remove all labels
Labels:

# If this is true then the source branch of the merge request will de deleted
# when this merge request is merged, takes 'true' or 'false'
Remove source branch when merged: True

# Name of the branch the branch the commit will be land on
Target Branch: master

# If 'true' then no users can comment, 'false' otherwise
Lock Discussion: False

# If 'true' then all commits will be squashed into a single one
Squash on merge: False

# If 'true' maintainers of the repository will be able to push commits
# into your branch, this is required for people rebasing-and-merging
Allow Maintainers to push: True
```

### edmr

Just like `vimr` it also edits attributes of merge requests but it only edits one at
a time and does so from the commandline. By passing arguments to the commandline one
can change the options listed with `edmr -l`.

```sh
$ edmr -l
target_branch -> a single string
state_event -> a single string
:description -> a single string
description -> a single string
remove_source_branch -> boolean
:title -> a single string
allow_maintainer_to_push -> boolean
squash -> boolean
assignee_ids -> multiple integers separated by whitespace
labels: -> one or more strings separated by whitespace
title: -> a single string
allow_collaboration -> boolean
milestone_id -> a single string
description: -> a single string
labels -> one or more strings separated by whitespace
discussion_locked -> boolean
:labels -> one or more strings separated by whitespace
assignee_id -> integer
title -> a single string
```

the `:` before and after a value indicates that it should be prefixed or suffixed, doing
`edmr MRNUM :title="[3.12] "` will prefix to the existing title of the merge request instead
of replacing it.

Basically `edmr` is the non-interactive relative of `vimr`.

> Replace title with head commit: `edmr MRNUM title="$(git show --oneline --format=%s)"`
