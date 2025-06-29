# Cargo Compatibility

List of things needed for Cargo compatibility...
- Build scripts
	- Need to support Cargo's `println` commands: https://doc.rust-lang.org/cargo/reference/build-scripts.html#outputs-of-the-build-script
	- Need to provide all of these environment variables: https://doc.rust-lang.org/cargo/reference/environment-variables.html#environment-variables-cargo-sets-for-build-scripts
	- Cargo lets build scripts coordinate with it via jobserver. Need to figure out if there's a way to bridge this to Nix: https://doc.rust-lang.org/cargo/reference/build-scripts.html#jobserver
		- I doubt this is feasible, and it's probably not used much, so for now nixrs can just not support it and it should error out on its own.
- Manifest
	- Need to be able to convert `Cargo.toml` to nixrs' internal crate type
- Unstable features
	- Metabuild https://doc.rust-lang.org/cargo/reference/unstable.html#metabuild
