# Features

Random collection of features that Cargo has and nixrs will need to also implement, or random ideas I think could be nice for nixrs to implement later.

I put them here so I can get them out of my mind and focus on what I need to do right now, then come back to these later.

- Building the standard library from source (https://doc.rust-lang.org/cargo/reference/unstable.html#build-std)
	- Can probably integrate this into toolchain options
- Specifying a custom codegen backend for rustc (https://doc.rust-lang.org/cargo/reference/unstable.html#codegen-backend)
- Offline mode that ensures Nix doesn't try to fetch things in its git cache
	- If Nix tries to update its git/tarball/etc cache, and fails because there's no wifi, the whole build fails
- Equivalent to Cargo profiles
	- Goal: Allow the user to easily change compilation settings with CLI flags, like `--debug` and `--release`
	- We have crate outputs, which can already do this to some extent, but aren't quite what we need:
		- Crate outputs are a package-level option (see  [dev-and-package.md](dev-and-package.md))
		- This needs to be a dev env-level option to quickly change enabled features, the target to build for, optimisation levels, etc.
	- Outputs and this will share some options; but outputs will have extra crate configurations that this doesn't, and this will have extra codegen options that outputs don't
		- This reduces boilerplate for this and restricts the options that outputs can use
