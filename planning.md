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

-[ ] Allow compiling code without copying its source code to the nix store
	- Only for local/on-disk deps
-[ ] Compile crate
	-[x] Internal crate format
		- This format is agnostic from both the nixrs Nix Module and Cargo.toml, allowing nixrs to compile crates in either format
		-[x] Crate metadata:
			-[x] Crate name
			-[x] Crate version
			-[x] Crate features
				- For checking if other crates try to enable a feature that don't exist
			-[x] Enabled crate features
			-[x] MSRV
		-[ ] Workspace info:
			- Mostly for generating the rust-analyzer cfg
			-[ ] If crate is a workspace member
	-[x] Check if crate has build.nix, call that if so
	-[x] Check if crate has crate.nix, if so:
		-[x] Evaluate as Nix module
		-[x] Convert to internal crate format
	-[ ] Check if crate has Cargo.toml, if so:
		-[ ] Convert Cargo.toml to nixrs internal crate format
	-[ ] Quick rebuilds
		-[ ] Allow reading crate source code w/o copying to Nix store
		-[ ] Incremental compilation
-[ ] Dependencies
	-[ ] Rust dependencies
		-[ ] Download crates from common sources:
			-[ ] crates.io @ Rust version requirement
			-[x] Allow arbitrary dependencies in the Nix store
			-[x] Local (on-disk) dependencies
		-[x] Recursively compile crates without evaluating their derivations
			- This is a temporary solution to dependencies
			- Long-term, nixrs should switch to something like pubgrub to properly build a dependency tree, merge compatible versions, and merge feature flags
				- https://nex3.medium.com/pubgrub-2fb6470504f
	-[ ] Link dependencies
		-[x] Need to allow linking to libraries in the Nix store
		-[ ] Investiage why Cargo has link restrictions & see if nixrs needs them too (Cargo doesn't allow multiple crates to link to the same static library)
			- https://doc.rust-lang.org/cargo/reference/build-scripts.html#the-links-manifest-key
	-[ ] Foreign dependencies
	-[ ] Binary/PATH dependencies
		-[x] Add to PATH
		-[ ] Make available to build scripts
		-[ ] Make available to nix shell
		-[ ] If the dep is a bin crate, build it first
	-[x] Make sure build files for dependencies aren't gc'd
-[ ] Compilation options
	-[ ] Custom linkers (e.g. mold)
	-[ ] Support codegen options (rustc -C help to see options)
	-[ ] Minimal binary size options
	-[ ] Investigate allowing/denying lints with -A, -W, -D
	-[x] Investigate emitting a different binary type with --emit
	-[ ] Investigate allowing direct custom arguments to rustc
-[ ] Workspace presets: A way to specify crates and compilation features to build together
	-[ ] Specify crates in a preset
	-[ ] Specify features for crates
	-[ ] Override dependencies
	-[ ] Specify target to build for, optimisation level, debug assertions, etc
	-[ ] Lint options
-[ ] Custom CLI subcommands
-[ ] rust-analyzer integration
	- https://rust-analyzer.github.io/book/configuration.html
	-[x] Generate basic rust-analyzer config
	-[ ] Generate crate list
	-[ ] Show compiler warnings/errors
	-[ ] Allow specifying a workspace preset for rust-analyzer to use
	-[x] Check if rust-analyzer auto-reloads rust-project.json
		- It does! :D
-[ ] Cargo integration: Generate a Cargo.toml for a crate, allowing workspaces to use nixrs but one (or more) crates from that workspace to be published on crates.io
-[ ] Targets
	- Rename to "outputs" so they're not confused with target triples?
	- https://doc.rust-lang.org/cargo/reference/cargo-targets.html
-[ ] CLI improvements
	-[ ] Finish bscli
	-[ ] Rewrite the Bash CLI in Rust with bscli
	-[ ] Currently the CLI stops looking for crate.nix files on the first one it finds. It should keep searching to look for a workspace outside of the crate.
		-[ ] If it finds a workspace, need to load settings from it
		-[ ] If it finds a workspace, need to use workspace target dir instead of crate target dir
-[ ] Optimise `installToolchain.nix`
