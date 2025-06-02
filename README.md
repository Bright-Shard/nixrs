# nixrs - fearless dependencies for Rust

nixrs is a build system for Rust that uses the [Nix programming language](https://nixos.org). It is a direct replacement for Cargo - for example, crates are declared in a `crate.nix` file, not `Cargo.toml` - but can still integrate with Cargo projects.

The goal of nixrs is to bring Nix's reproducable builds to Rust. All dependencies - from crates on crates.io, to static C libraries a Rust project links with, to CLI tools your project needs for development - can be managed with nixrs. Thus, other

> **DISCLAIMER:**
>
> nixrs is *heavily* work-in-progress. The below README is the end goal for the project, but currently only a fraction of those features are actually implemented.
>
> You can see examples where I test nixrs in the `examples/` folder, and the project's massive todo list in [`planning.md`](planning.md).
>
> **To be perfectly clear, nixrs is probably not ready for you to use in its current state**. See the "current limitations" list at the bottom for a list of major missing features.



# Cargo compatibility

nixrs crates can depend on normal Cargo projects, so any existing crate on crates.io can be added as a dependency just like with Cargo. nixrs also has a `cargo-compatibility` option that, when enabled, will cause nixrs to generate a `Cargo.toml` file for your crate.

However, nixrs has some features Cargo does not (these additional features are discussed below). Obviously, these features cannot be translated into `Cargo.toml` - so when `cargo-compatibility` is enabled, you won't be able to use these nixrs features, and nixrs will error if you attempt to do so.

> Note: cargo-compatibility is current not implemented.



# When/Why should I use this?

nixrs isn't always compatible with Cargo, so some nixrs crates can't be published on crates.io. Therefore, nixrs is probably a bad idea for libraries.

nixrs is largely intended for large programs written in Rust that need more flexibility than Cargo can provide. nixrs offers all of the same features Cargo offers, and adds the following:

- **Dependencies Beyond crates.io**: Because nixrs is based on Nix, you can specify any code as a dependency - regardless of how it's hosted (crates.io, GitHub, a zip file, etc.) or what language it's written in.
- **Development Dependencies**: Many large-scale projects require third-party linters, build tools, or runtimes for development. For example, my operating system [bs](https://github.com/bright-shard/bs) requires QEMU to test the OS during development. Other large scale projects may even have internal CLIs dedicated for their specific codebase. nixrs allows you to specify any binary as a dependency, so every developer has the tooling they need OOTB.
- **Toolchain Management**: Manage your Rust version, edition, targets, and components from directly within nixrs. No need to manage Cargo and Rustup separately. This ensures all maintainers use the same Rust version, without even having to think about installing it.
- **Reliable Builds**: nixrs makes the same reproducable build guarantees that you'd expect from any Nix package. Dependencies that build on one computer will build on all computers (unless, of course, a crate explicitly doesn't support certain OSes/architectures).
- **rust-analyzer Support**: You can configure rust-analyzer from directly within nixrs. Those settings will load regardless of what IDE you and your collaborators use.
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
> - nixrs does not currently support flakes, since flakes are unstable. nixrs does its best to only use stable Nix features so that you don't need to set any additional options to use it.

A barebones `crate.nix` looks like this:

```nix
{ ... }:
{
  name = "hello_world";
  version = "0.0.1";
  edition = 2024;

  meta.authors = [ "me!" ];
}
```

As you can see, `crate.nix` strongly resembles `Cargo.toml`. This is intentional - Cargo is already really awesome, so much of nixrs is inspired by it. Also like Cargo, you can build your crate with `nixrs build` and run it with `nixrs run`.



# nixrs API

nixrs is split into two portions - a Nix API, and a Nix Module. The module powers `crate.nix` and the CLI. However, nixrs aims to be very flexible, and there may be some cases where using the CLI doesn't work well for a project - for example, a large multi-language project where the Rust crates are only one portion of the larger codebase.

In a situation like that, you can skip the Nix module and just use the nixrs API directly. The nixrs module intentionally just wraps around the nixrs API, so you won't lose any features by doing this. This allows you to use Nix as a build system for many languages and have your Rust crates just be one portion of the system - handled for you by nixrs.

There aren't many docs written for the nixrs API outside of the nixrs source code. You can see all of nixrs' functions in `nixrs/default.nix`. You can look in `nixrs/config` for an example of using the nixrs API - that portion of the codebase glues the nixrs Nix Module to the nixrs API and calls all the correct functions to build a crate configured with `crate.nix`.

> Note: The nixrs API is currently extremely unstable because nixrs is still very WIP.



# Current Limitations

- (wip) nixrs doesn't support dependencies
- (wip) nixrs doesn't integrate with rust-analyzer
- the nixrs CLI doesn't accept flags for running unit tests or building in release mode
- nixrs doesn't have any form of workspaces
- nixrs lacks a lot of compilation options that Cargo has
- miri requires special sysroot settings and tries to manage dependencies on its own. As such I haven't yet figured out how to get it to run in a nixrs project.
