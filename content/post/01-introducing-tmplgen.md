---
title: "Introducing tmplgen"
date: 2019-02-03T22:00:58+01:00
draft: false
aliases:
    - /posts/01-introducing-tmplgen/
    - /post/01-introducing-tmplgen/
---

Some time ago [maxice8](https://github.com/maxice8) had told me about [gemnator](https://github.com/maxice8/meltryllis/blob/d3b7383e95a3be987a4a252530347ae9a7b6a266/bin/gemnerator), a simple script written in SH
to generate Void Linux build template files for Ruby Gems. It pulls the neccessary data (e.g. the newest version, dependencies etc.) from  the rubygems.org API and generates a ready to use template from it.
I really liked the idea and wanted to improve on it, e.g. by adding more sources to query (such as crates.io, metacpan.org) and adding more functionality to it, like updating existing templates.

<!--more-->

# How everything started out

I've started writing tmplgen in late October 2018, mainly to get into writing Rust (which is an amazing programming language, but I won't get too much into this in this article).
When I started out tmplgen only did one thing: writing build templates for crates (Rust packages hosted on crates.io). Running `cloc` shows us how tiny it was:

```
-------------------------------------------------------------------------------
Language                     files          blank        comment           code
-------------------------------------------------------------------------------
Rust                             1             25              0             76
YAML                             1              0              0             19
-------------------------------------------------------------------------------
SUM:                             2             25              0             95
-------------------------------------------------------------------------------
```

It basically only consisted of a `main.rs`which used the [crates_io_api](https://creates.io/crates_io_api) crate to download the info of a crate, call `git` to figure out the maintainer's name and eMail
and then repeatedly call `replace` (think of it as Rust's sed 's/')  on a generic template file which was built into tmplgen. There was no error handling to speak of, it'd simply panic if anything
(e.g. downloading, figuring out the maintainer via git) went wrong.

# Supporting more data sources

tmplgen got support for creating build files for Ruby Gems only a week after its creation, on November 2nd. Since it was a pretty simple (Yeah, let's go with that) project at that point adding support for it was pretty trivial, see [c5974bbe4b](https://github.com/Cogitri/tmplgen/commit/c5974bbe4bf6b02bcee438cdf860ddc85ea541ed):

```
+fn gem_info(gem_name: &String) -> Result<PkgInfo, rubygems_api::Error> {
+    let client = rubygems_api::SyncClient::new();
+
+    let query_result = client.gem_info(gem_name)?;
+
+    let pkg_info = PkgInfo {
+        pkg_name: gem_name.clone(),
+        version: query_result.version,
+        description: query_result.info.unwrap_or_default(),
+        homepage: query_result.homepage_uri.unwrap_or_default(),
+        license: query_result.licenses.unwrap_or_default(),
+    };
+
+    Ok(pkg_info)
+}
+
 // Writes the PkgInfo to a file called "template"
 fn write_template(pkg_info: &PkgInfo, force_overwrite: bool) -> Result<(), std::io::Error> {
     let template_in = include_str!("template.in");
@@ -153,14 +168,18 @@ fn main() {
     let help_tuple = help_string();
     let pkg_name = help_tuple.0;
     let tmpl_type = help_tuple.1;
    let force_overwite = help_tuple.2;
 
     println!(
         "Generating template for package {} of type {}",
         pkg_name, tmpl_type
     );
 https://gist.github.com/4da080659b0821759b7525bc242d35d2
-    let pkg_info = crate_info(&pkg_name);
+    let pkg_info= if tmpl_type == "crate" {
+        crate_info(&pkg_name)
+    } else {
+        gem_info(&pkg_name).unwrap()
+    };
 }
```

You can see that that commit already had some (basic) error handling! Rust has a built in type to make handling errors easy: [Result](https://doc.rust-lang.org/std/result/)! 
A function which may fail can return a `Result<(), Error>` where `()` is the type we actually want to return (`()`would be the 'unit type', meaning we don't have anything to return). E.g. in the
`gem_info` function we return a `Result<PkgInfo, rubygems_api::Error>`. If the function runs sucessfully, it runs `Ok(pkg_info)`which means that the the function
has been run sucessfully. If an error occurs before (and is handeled, e.g. via `?`) the Result won't contain the `PkgInfo` but instead only a `rubygems_api::Error`.
Since we still run `gem_info(&pkg_name).unwrap()` this doesn't exactly help us just now, the program still panics, just like before!

# Implementing actual error handling into tmplgen

For better error messages (or even handling errors gracefully) we need to handle errors better. You've already received a glimpse at `rubygems_api::Error`. Rust crates usually implement
their own set of `Errors` (sometimes called `ErrorKinds` instead), see [here](https://github.com/Cogitri/tmplgen/blob/0b60fbe17ee9f5985b4050dc251e15ef8fabe267/src/lib/errors.rs) for
a list of tmplgen's current errors. Here's one example:

```
#/// The Error enum containing all Errors that may occur when running tmplgen
#[derive(Clone, Debug, Eq, PartialEq, Ord, PartialOrd, Hash, Fail)]
pub enum Error {
    #[fail(display = "Failed to read/write the template! Error: {}", _0)]
	File(String),
	...
```

This `Error` is thrown if tmplgen can't read/write the template. With this the error message when writing a templates may look like this:

```
Failed to read/write the template! Error: File exists (os error 17)
```

Otherwise it'd look this this:

```
thread 'main' panicked at 'File(Os { code: 17, kind: AlreadyExists, message: "File exists" })', src/libcore/result.rs:1009:5
note: Run with `RUST_BACKTRACE=1` for a backtrace.
```

The former clearly states what _actually_ went wrong (Reading/Writing the template),
instead of only panicking and telling us that some file (what file?!?) already exists.

This is mainly thanks to [failure](https://crates.io/failure), an amazinh crate which makes error handling rather pleasent.

# Making the API nice to use

tmplgen simply kept growing until version 0.9.0, adding some nice features like automatically figuring out from what source a package might come from, so that one wouldn't have to do `tmplgen -t gem mocha` to create a package for the
Ruby Gem `mocha`anymore, but instead simply run `tmplgen mocha` in [7e6ea50f2](https://github.com/Cogitri/tmplgen/commit/7e6ea50f2451393550a4f49bb096c2c1610826cb). This was rather easy to pull of at first, but small changes (such as this one)
resulted in rather big diffs since I just piled up functions in `helpers.rs`. Using the API also was rather confusing:

```
// Get the PkgType of this crate
let pkg_type = figure_out_provider("tmplgen").unwrap();
// Get a PkgInfo struct of this crate
let pkg_info = get_pkginfo("tmplgen", pkg_type).unwrap();
// Don't overwrite existing templates
let force_overwrite = false;
// This isn't a recursive dep, error out if there's an error
let is_rec = false;

// Actually write the template
template_handler(&pkg_info, pkg_type, force_overwrite, is_rec);
```

## Builder API pattern to the rescue!

I've decided to get tmplgen to 1.x by changing tmplgen over to a [Builder API](https://doc.rust-lang.org/1.0.0/style/ownership/builders.html#non-consuming-builders-(preferred):). It was supposed to look like this:

```
pub struct TmplHandle {
	pkg_name: String,
	pkg_type: String,
}

impl TmplHandle {
	/// Return a TmplHandle to build upon.
	pub fn new(pkg_name: String, pkg_type: String) -> TmplHandle {
		TmplHandle { pkg_name, pkg_type }
	}

	/// Generate a template. Takes in a PkgInfo which contains all necessary info
	pub fn gen_tmpl(pkg_info: PkgInfo){
		...
	}
```

This kind of sucked. One still had to call some random function from `helper.rs`to figure out the pkg_type to use and get a PkgInfo by themself.

In the end I've gone with the following:

```
pub struct TmplBuilder {
    pub pkg_name: String,
    pub pkg_type: Option<PkgType>,
    pub pkg_info: Option<PkgInfo>,
}

impl TmplBuilder {
    pub fn new(pkg_name: &str) -> Self {
        ...
    }

    pub fn from_pkg_info(pkg_info: PkgInfo) -> Self {
        ...
    }

    pub fn get_type(&mut self) -> Result<&mut Self, Error> {
        ...
     }

    pub fn set_type(&mut self, pkg_type: PkgType) -> &mut Self {
        ...
    }

    pub fn get_info(&mut self) -> Result<&mut Self, Error> {
        ...
    }

    pub fn set_info(&mut self, pkg_info: PkgInfo) -> &mut Self {
        ...
    }

    pub fn is_built_in(&self) -> Result<bool, Error> {
        ...
    }

    pub fn gen_deps(&self, tmpl_path: Option<&str>) -> Result<Vec<Template>, Error> {
		....
    }

    pub fn update(&self, old_template: &Template, update_all: bool) -> Result<Template, Error> {
		...
    }

    pub fn generate(&self, prefix: bool) -> Result<Template, Error> {
		...
    }
```

Generating a template now works like this:

```
let tmpl_builder = TmplBuilder::new(pkg_name)
	.get_type()?
	.get_info()?
	.generate(true)?;
```

This is way more intuitive than searching for some random function which may (or may not) get the pkg_type and pkg_info for you.

It's also very nice to use in an IDE:

![Smart IntelliSense](https://cogitri.github.io/post/post-01.png)

See [the source](https://github.com/Cogitri/tmplgen/blob/master/src/lib/tmplwriter.rs) for more details.

Overall tmplgen has been a great experience for me. It helped me getting into Rust and understand different ways to package software.
