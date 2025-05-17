# buildCrate

This package is called by the CLI. It loads the Nix module from `crateOptions` that `crate.nix` configures, then reads all of the settings in those options and passes them on to `nixrs` to compile the crate.
