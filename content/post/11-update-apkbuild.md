---
title: "APKBUILD.vim: updates, new stuff, better"
date: 2020-11-03T23:59:41-03:00
draft: false
---

> Article by Leo <thinkabit.ukim@gmail.com>

This is an update on
[APKBUILD.vim: filetype, plugins, syntax and linters for APKBUILDs on vim][1],
as of now APKBUILD.vim is under very active constant development, and it will
remain this way until all features have been implemented and there is nothing
else to remove.

In fact the development is so fast that the article was outdated the moment
it arrived. So lets catch up on everything that happened until
247b647ba47cb9a091020e4e5c4df7894cc05b1d.

If you wish to follow along then here are the [commits][2].

<!--more-->

## Rename

When [APKBUILD.vim][3] was started it used `APKBUILD` as the name of the
filetype, this turned out to be out of line with everyone else, if one
looks at the filetypes provided by vim they are **all** in lowercase.

With that we mind the filetype is now `apkbuild` and (hopefully) every reference
has been changed to fit the new name.

Now we look at what changed in each directory that is worth looking at:

### Syntax

Certainly one of the most, if not the most, important part of what APKBUILD-vim
provides.

* In the context of `pkgname=` single and double quotes are now treated as
  Error
* Keywords used by `abuild` are now matched even if they are not at the root of
  the document. This means that keywords used in conditionals and functions
  now are highlighted as if they were at the root of the APKBUILD.
* Set b:is_posix before loading sh.vim, this is more in-inline with what the
  ash shell provides while not overdoing it by calling is_bash. This means
  some shell constructs that are normally used like variable substitution are
  no longer highlighted as Error.
* Import 2 variable substitution patterns that are guarded under b:is_bash but
  are supported in ash and used in APKBUILDs:
  * `${var//pattern/}`
  * `${var:x:y}`
* Remove AbuildSubComment, it is no longer necessary and was a filthy hack,
  sh.vim provides better support for comments and we should use it as much
  as possible.

### ftplugin

* Register `apkbuild_fixer` with `ale#fix#registry#Add` and set `b:ale_fixers`
  to recognize `apkbuild_fixer`.

### ftdetect

Only small changes.

* use the `setfiletype` function instead of doing `set filetype=`. This is used
  by the filetypes shipped in vim to avoid setting it more than once as
  `setfiletype` does nothing if a filetype is already set.

### autoload

* apkbuild_fixer` has been added for ALE. This fixer runs `apkbuild-lint`
  on a given file then removes all policy violations it knows how to fix.

### doc

`doc` is a completely new directory. Currently, it only contains documentation for using
and configuring ALE. It is expected that this will be upstreamed one day and
hopefully replaced by documentation about APKBUILD and other things.

## Upstreaming

We also started the process of upstreaming the 2 linters we wrote that use
`apkbuild-lint` and `secfixes-check`. You can check out the Pull Request
[here][5]

[1]: /posts/08-meet-apkbuild.vim
[2]: https://gitlab.alpinelinux.org/Leo/apkbuild.vim/-/commits/master
[3]: https://gitlab.alpinelinux.org/Leo/apkbuild.vim
[4]: https://github.com/dense-analysis/ALE
[5]: https://github.com/dense-analysis/ale/pull/3424
