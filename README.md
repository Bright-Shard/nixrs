# nixrs - an alternative build system for Rust

nixrs is a build system for Rust that uses the [Nix programming language](https://nixos.org). It is a direct replacement for Cargo - for example crates are declared in a `crate.nix` file, not `Cargo.toml`.

> **DISCLAIMER:**
>
> nixrs is *heavily* work-in-progress. The below README is the end goal for the project, but it doesn't have all of these features yet.
>
> The current status is basically a proof-of-concept project that allows setting options in `crate.nix` and can compile a Rust project with rustc. Not all options in `crate.nix` are currently supported.
>
> You can see examples where I test nixrs in the `examples/` folder.



# Cargo compatibility

nixrs crates can depend on normal Cargo projects, and any crate on crates.io can be added as a dependency just like Cargo. nixrs also has a `cargo-compatibility` option that, when enabled, will cause nixrs to generate a `Cargo.toml` file for your crate.

However, nixrs has some features Cargo does not (these additional features are discussed below). Obviously, these features cannot be translated into `Cargo.toml` - so when `cargo-compatibility` is enabled, you'll only be able to use nixrs features that also exist in Cargo. nixrs will emit errors if you attempt to use any other features.



# When/Why should I use this?

nixrs isn't always compatible with Cargo, so some nixrs crates can't be published on crates.io. Therefore, nixrs is probably a bad idea for

nixrs is largely intended for large programs written in Rust that need more flexibility than Cargo can provide. nixrs offers all of the same features Cargo offers, and adds the following:

- **Dependencies Beyond crates.io**: Because nixrs is based on Nix, you can specify any code as a dependency - regardless of how it's hosted (crates.io, GitHub, a zip file, etc.) or what language it's written in.
- **Development Dependencies**: Many large-scale projects require third-party linters, build tools, or runtimes for development. For example, my operating system [bs](https://github.com/bright-shard/bs) requires QEMU to test the OS during development. Other large scale projects may even have internal CLIs dedicated for their specific codebase. nixrs allows you to specify any binary as a dependency, so every developer has the tooling they need OOTB.
- **Toolchain Management**: Manage your Rust version, edition, targets, and components from directly within nixrs. No need to manage Cargo and Rustup separately.
- **Reliable Builds**: nixrs makes the same reproducable build guarantees that you'd expect from any Nix package. Dependencies that build on one computer will build on all computers.
- **rust-analyzer Support**: You can configure rust-analyzer from directly within nixrs. Those settings will load regardless of what IDE you - or your collaborators - use.
- **...and more**: post-build scripts, direnv integration, built-in support for linker scripts, and many other features that'd take too long to list here.



# Installation

Nixrs must be installed with Nix. To install the latest version, add this to your list of packages (in `configuration.nix`, `shell.nix`, or whatever else):

```nix
(pkgs.callPackage (pkgs.fetchFromGitHub {
	owner = "bright-shard";
	repo = "nixrs";
	rev = "main";
}) { })
```

Nix will error about a hash mismatch. Copy the hash from the error message, then add `hash = "<paste hash here>";` to the `fetchFromGitHub` arguments. If you would like to install a specific version of nixrs, change `rev` to that version.



# Usage

nixrs is largely inspired by Cargo, so nixrs projects are structured similarly to Cargo projects. The largest two differences are that nixrs uses `crate.nix` (instead of `Cargo.toml`) for configuration, and is written in Nix instead of TOML. If you aren't familiar with Nix, don't worry - 90% of what you need is Nix tables, which are similar to Python dictionaries or JSON.

> For those of you familiar with Nix:
>
> - nixrs uses a standard [Nix module](https://nix.dev/tutorials/module-system/index.html), so it's the same format used by NixOS' `configuration.nix` file.
> - nixrs does not currently support flakes, since flakes are unstable.

A barebones `crate.nix` looks like this:

```nix
{ ... }:
{
  config = {
    name = "hello_world";
    version = "0.0.1";
    edition = 2024;

    meta.authors = [ "me!" ];
  };
}
```

As you can see, `crate.nix` strongly resembles `Cargo.toml`. This is intentional.

Once you have a crate setup, you can build with `nixrs build` and run it with `nixrs run` - also like Cargo.
