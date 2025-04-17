# buildCrate.nix improvements

- Support building a test harness with --test
- Investigate allowing/denying lints with -A, -W, -D
- Support codegen options with -C (-C help to see options)
- Investigate emitting a different binary type with --emit
- Investigate allowing custom arguments to rustc
- Allow specifying custom linkers (e.g. mold)



# workspace features

- Workspace presets: A way to specify crates and compilation features to build together
	- Specify crates in a preset
	- Specify features for crates
	- Override dependencies
	- Specify target to build for, optimisation level, debug assertions, etc
	- Preset for rust-analyzer?



# cli features

- Currently the CLI stops looking for crate.nix files on the first one it finds. It should keep searching to look for a workspace outside of the crate.
- Allow custom subcommands



# misc

- rust-analyzer integration
	- https://rust-analyzer.github.io/book/configuration.html
- Cargo integration: Generate a Cargo.toml for a crate, allowing workspaces to use nixrs but one (or more) crates from that workspace to be published on crates.io
