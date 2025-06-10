# these are done

- wrap rustc & actually compile a crate
- basic Nix module layout
- lower level nixrs API for when the module can't be used
- toolchain management
- shell.nix integration



# known bugs

-[x] Cargo allows compiling crates with a - in the name. When nixrs does the same thing rustc errors.
	- This is because a package != a crate. Packages can have -, but crates cannot.
	- Cargo builds packages, nixrs builds crates but should instead build packages.
	- I'm not clear if packages are an actual rustc setting or just what Cargo calls its crates. For now nixrs replaces `-` with `_` in the crate name, but I should look into this more in case I'm missing something else.
	- https://doc.rust-lang.org/book/ch07-01-packages-and-crates.html



# remaining todos

Basically CLI improvements, supporting dependencies, workspaces, and more compilation options

-[ ] Command for running binary crates
-[ ] Command for building & running a test harness
-[ ] Code dependencies
	- There will be multiple types of dependencies nixrs needs to handle.
	-[ ] Rust dependencies
		- Need to build dependency tree, then go through and make a flat list of dependencies with unified features and versions
		-[ ] Need to allow downloading from common sources:
			-[ ] crates.io @ Rust version requirement
			-[x] Allow arbitrary dependencies in the Nix store
		-[ ] Determine if dependency is based in Cargo or nixrs
			-[ ] For nixrs dependencies, recursively add sub-dependencies to dependency tree
				-[ ] Cyclical dependency detection: If current crate is already in the dependency tree, in one straight branch to the root of the tree, error
		-[ ] Flatten dependency tree into dependency list
			-[ ] Start at top of tree
			-[ ] For each branch, descend to bottom of branch and:
				-[ ] If crate is already in dependency list, and its version can be merged with the existing entry:
					-[ ] Merge crate version
					-[ ] Merge crate features
				-[ ] Otherwise, add crate to dependency list
	-[ ] Link dependencies
		-[x] Need to allow linking to libraries in the Nix store
		-[ ] Investiage why Cargo has link restrictions & see if nixrs needs them too (Cargo doesn't allow multiple crates to link to the same static library)
			- https://doc.rust-lang.org/cargo/reference/build-scripts.html#the-links-manifest-key
	-[ ] Make sure build files for dependencies aren't gc'd
-[ ] Binary dependencies
	-[ ] Should integrate with direnv/shell.nix to allow specifying binary dependencies needed for developing in the workspace
	-[ ] Should make those dependencies available to build.rs/postbuild.rs
-[ ] Compilation options
	-[ ] Custom linkers (e.g. mold)
	-[ ] Support codegen options (rustc -C help to see options)
	-[ ] Minimal binary size options
	-[ ] Investigate allowing/denying lints with -A, -W, -D
	-[ ] Investigate emitting a different binary type with --emit
	-[ ] Investigate allowing direct custom arguments to rustc
-[ ] Workspace presets: A way to specify crates and compilation features to build together
	-[ ] Specify crates in a preset
	-[ ] Specify features for crates
	-[ ] Override dependencies
	-[ ] Specify target to build for, optimisation level, debug assertions, etc
	-[ ] Lint options
-[ ] Currently the CLI stops looking for crate.nix files on the first one it finds. It should keep searching to look for a workspace outside of the crate.
	-[ ] If it finds a workspace, need to load settings from it
	-[ ] If it finds a workspace, need to use workspace target dir instead of crate target dir
-[ ] Custom CLI subcommands
-[ ] rust-analyzer integration
	- https://rust-analyzer.github.io/book/configuration.html
	-[ ] Allow specifying a workspace preset for rust-analyzer to use
-[ ] Cargo integration: Generate a Cargo.toml for a crate, allowing workspaces to use nixrs but one (or more) crates from that workspace to be published on crates.io
-[ ] Targets
	- Rename to "outputs" so they're not confused with target triples?
	- https://doc.rust-lang.org/cargo/reference/cargo-targets.html
-[ ] Make sure help menu prints in 2 columns
