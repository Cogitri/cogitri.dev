---
title: "Contributing to Alpine Linux: making Merge Requests"
date: 2019-10-29T11:28:05-03:00
draft: false
aliases:
    - /posts/02-gitlab-alpinelinux-v4-api/
    - /post/02-gitlab-alpinelinux-v4-api/
---

# Introduction

> Guest article by maxice8

Some time ago, [Alpine Linux](https://alpinelinux.org) started using their self-hosted
[GitLab instance](https://gitlab.alpinelinux.org) to accept contributions via merge requests.

I wanted to move to it immediately as using their GitLab instance is planned to be the main repo (it
is currently a mirror to git.alpinelinux.org).

# How it was before

Before using their GitLab instance I used their [GitHub repo](https://github.com/alpinelinux/aports) to
contribute, I would use the amazing [hub](https://github.com/github/hub) tool, which after login with my
personal access token would allow me to easily check out pull requests and merge them from the CLI.

The scripts for it are very simple, most of the logic is on hub and a few lines of shell just wrap around
it for my most common use cases.

This one uses hub to checkout a PR someone has made:

```sh
#!/bin/sh
set -eu
while [ $# -gt 0 ]
do
	if [ $# -gt 1 ]
	then
		args="$1 $2"
		shift 2
	else
		args="$1"
		shift 1
	fi
	hub pr checkout $args
	pullp
done
```

# Moving to GitLab

GitLab doesn't have a tool like hub that makes it super easy to interact with the GitLab V4 API like
hub does with the GitHub API. So I turned into accessing the API by myself with the ever trustworthy curl.

## Finding the endpoint

Since GitLab allows self hosting, the first thing you have to do is find our respective GitLab endpoint. GitHub
is a centralized proprietary service so it doesn't have this issue.

This is the following code present in all my scripts that deal with GitLab (I believe the comments
are enough to tell what they are for and what they meant).

```sh
# Try to detect host, strip the .git suffix
# This is where the domain is, most normally gitlab.com
# but also works with other custom domains.
HOST="$(git config remote.upstream.url | cut -d / -f -3)"

# This is the ENDPOINT of the project you forked, if we call this with
# curl we get a JSON payload that describes the repo, including stuff like
# its :id and :name
ENDPOINT="$HOST"/api/v4/projects/"$origin_owner"%2F"$origin_repo"

# This is the ENDPOINT of the project itself, we need to get its :id value to
# pass as the 'target_project_id'
UPSTREAM_ENDPOINT="$HOST"/api/v4/projects/"$upstream_owner"%2F"$upstream_repo"
```

## Finding the project id

Each project has its own id, which we need to pass in the request to the GitLab API so it
knows which repo we target when creating the merge request.

```sh
_get_project_id() {
	repo="$(echo "$1" \
			| sed -e 's|https://||g' -e 's|%2F|.|' \
			| tr '/' '.' )"

	# Create cache directory if it doesn't exist
	[ -d "$XDG_CACHE_HOME"/mkmr ] || mkdir -p "$XDG_CACHE_HOME"/mkmr

	# The project ID is cached, read it out
	if [ -f "$XDG_CACHE_HOME"/mkmr/"$repo" ]; then
		cat "$XDG_CACHE_HOME"/mkmr/"$repo"
		return 0
	fi

	# Call the GitLab API to see the id of the repo and write it to the cache
	curl --silent "$1" | jq '.id // empty' | tee "$XDG_CACHE_HOME"/mkmr/"$repo"

	[ -s "$XDG_CACHE_HOME"/mkmr/"$repo" ] || return 1
}
```

The code above finds the project id via a request to the GitLab API which can be slow
so we cache the id of the project so you don't need to call it every time you have to
make a merge request.

## Crafting the JSON payload

The GitLab API takes a JSON payload for its requests, so we need to craft one in shell
for it, which is easier than initially thought.

This is the first part of the payload, and will always appear, regardless of whatever
options the user has passed to the script when creating the merge requests

```sh
	# JSON payload that will be used to create the branch
	BODY="{
		\"id\": \"${origin_owner}%2F${origin_repo}\",
		\"source_branch\": \"$(git rev-parse --abbrev-ref HEAD)\",
		\"remove_source_branch\": true,"
```

The second part adds labels to the merge request if the user passed them via the --labels
option. It also sets the description of the merge request, which the user can set by passing
--description and/or passing --edit (edit with $EDITOR).

> the A-upgrade label is automatically added if it detects an Alpine Linux upgrade commit
> <repo>/<pkg>: upgrade to <pkgver>
>
> The A-add label is automatically added if it detects an Alpine Linux add commit
> <repo>/<pkg>: new aport
>
> The A-move label is automatically added if it detects an Alpine Linux move commit
> <newrepo>/<pkg>: move from <oldrepo>

Note that we use awk to convert all newlines to literal \n, this is required and GitLab will
translate them back from literal \n to newlines.

```sh
	# If we set labels then append it to body
	if [ -n "$LABEL" ]; then
		BODY="$BODY
		\"labels\": \"$LABEL\","
	fi

	if [ -n "$DESCRIPTION" ]; then
		BODY="$BODY
		\"description\": \"$(printf "%s" "$DESCRIPTION" | awk '{printf  "%s\\n", $0}' )\","
	fi
```

The last part sets the target_branch, which is where you want to merge the merge request into,
most of the time it is the master branch, but in some cases you might want to merge into other
branches with --target-branch. 

> There is also logic specific to Alpine Linux for setting the target_branch to one of its
> stable branches for backporting

If the branch only contains one commit deviating from the target branch it sets the title and description of the merge request to the commit's text. If there are multiple deviating commits it allows the user to pick one of the commits to use its text. Users can also pass the `--title`  option to the script to write their own title

The assignee_id is rarely used since it is very annoying to use but if you pass it with --assignees then
the user that matches the id will be marked as assignee on the merge request.

```sh
	BODY="$BODY
		\"target_branch\": \"$TARGET_BRANCH\",
		\"title\": \"$TITLE\",
		\"assignee_id\": \"$ASSIGN\",
		\"target_project_id\": $PROJECT_ID
	}";
```

## Calling the API

After the JSON payload is done we now call the API with curl.

For it we have to provide our own personal access token. To do it we use the
freedesktop [Secrets API](https://freedesktop.org/wiki/Specifications/secret-storage-spec/secrets-api-0.1.html)
and [secret-tool(1)](https://manpages.ubuntu.com/manpages/bionic/man1/secret-tool.1.html) to
query the system keyring for the private token. Users can just put the value for
their own personal access token.

```sh
	JSON="$(curl -X POST "$ENDPOINT"/merge_requests \
			--header "PRIVATE-TOKEN: $(secret-tool lookup Path a.o/gitlab/token/mkmr)" \
			--header "Content-Type: application/json" \
			--data "$BODY" --silent)"

	WEB_URL="$(echo "$JSON" | jq '.web_url // empty')"

	if [ -z "$WEB_URL" ]; then
		echo "$JSON" | jq -r .
	else
		echo "$WEB_URL" | tr -d '"'
	fi
```
