# nixrs - fearless dependencies for Rust

> **WIP Disclaimer**
>
> nixrs is very much work-in-progress. It is probably not yet suitable for your project and needs a couple more weeks to cook. There's a current limitations list at the bottom of this README with the most egregious missing features.
>
> This README is written as if nixrs is completed. Some of the features it advertises may not be implemented yet.

nixrs is a build system for Rust powered by [Nix](https://nixos.org). It is a direct replacement for Cargo - for example, crates are declared in a `crate.nix` file, not `Cargo.toml` - but nixrs can still integrate with Cargo projects.

> **Platform Support**
>
> Let's just get this out of the way - the Nix package manager can only be installed on Unix systems (e.g. Linux and macOS). Windows cannot natively run nixrs. You'll have to run nixrs through WSL (see, for example, [NixOS-WSL](https://github.com/nix-community/NixOS-WSL)). You could also do yourself a favor and make the switch to Linux ;)

nixrs intends to provide all of the features offered today by Cargo and Rustup, plus complete dependency management for projects and guaranteed reproducible builds. The dream of nixrs is that a developer can simply open a project and have every tool they need ready to go OOTB.



# Complete Dependency Management

Cargo allows you to specify dependencies, but it only considers one kind of dependency: The Rust crates your code needs to build and run. There's many other kinds of dependencies that your project probably uses today - for example:

- A specific C library your code needs to link against
- Dedicated CLI tools - the Tauri CLI, wasm-bindgen CLI, dioxus CLI, etc.
- Custom internal tooling, such as linters or CLIs for running your test suite
- A specific Rust version or toolchain, with support for specific targets (e.g. wasm) or features (e.g. miri)

In traditional Cargo-based codebases, all of the above dependencies have to be installed manually by developers outside of Cargo (though there may be programs to help with this, e.g. rustup). In nixrs, all of these dependencies and more can be specified declaratively.

Dependencies are also installed per-project, meaning that two projects can use two different versions of `wasm-bindgen-cli` or other software with no issue.



# Reproducible Builds

In Cargo projects today, there are a plethora of reasons why a project might build on one developer's machine, but not yours:

- You installed the wrong Rust version, or haven't updated it in a while so now it's missing features.
- You didn't install some C library that a crate links against in its `build.rs`.
- You have the wrong version of a CLI like `wasm-bindgen` installed.

Notice how all of these errors stem from dependencies that Cargo doesn't handle. Because nixrs has complete dependency management, down to the patch version of `wasm-bindgen-cli`, it prevents this entire class of compilation errors. No need to set up a developer environment or figure out what packages you're missing to start working on a project - just build your project with nixrs, and it takes care of everything.



# Cargo Compatibility

> Note: The features described in this section are not yet implemented. This is the goal for nixrs before it's ready to release.

nixrs crates can depend on normal Cargo projects, so any existing crate on crates.io can be added as a dependency just like with Cargo. nixrs also has a `cargo-compatibility` option that, when enabled, will cause nixrs to generate a `Cargo.toml` file for your crate. Keep in mind that nixrs has many features Cargo does not, and these features cannot be translated into a `Cargo.toml`.



# Installation

nixrs requires both Nix and Nixpkgs. To install the CLI, just call `pkgs.callPackage`. To use the nixrs API, just import `path/to/nixrs/nixrs`.

Examples:
```nix
let
	# Download the latest nixrs version
	nixrs = builtins.fetchGit {
		url = "https://github.com/bright-shard/nixrs.git";
		ref = "main";
	};
	# Or download a specific release
	nixrs = pkgs.fetchFromGitHub {
		owner = "bright-shard";
		repo = "main";
		rev = "invalid"; # Put version here
		hash = "invalid"; # Put the hash the error message gives you here
	};
in

# Install the CLI
pkgs.callPackage nixrs { }

# Or import the nixrs library to use the nixrs API in some other Nix code
import "${nixrs}/nixrs" {
	# Optional, specify the registries that nixrs can download crates from
	# (see nixrs/default.nix)
	registries = {};
	# Optional, override the version of nixpkgs that nixrs uses
	pkgs = myCustomNixpkgs;
}
```



# Usage

nixrs is largely inspired by Cargo, so nixrs projects are structured similarly to Cargo projects. The largest two differences are that nixrs uses `crate.nix` (instead of `Cargo.toml`) for configuration, and is written in Nix instead of TOML. If you aren't familiar with Nix, don't worry - 90% of what you need is Nix tables, which are similar to Python dictionaries or JSON.

> For those of you familiar with Nix:
>
> - nixrs uses a standard [Nix module](https://nix.dev/tutorials/module-system/index.html), so it's the same format used by NixOS' `configuration.nix` file.
> - nixrs does not currently support flakes, since flakes are unstable. nixrs does its best to only use stable Nix features so that you don't need to set any additional options to use it.
> - Currently, downloading a toolchain with nixrs involves an import from derivation. It's not a bad one (it downloads one TOML file and parses it), but it is there. This will be removed when dynamic derivations are stable.

A barebones `crate.nix` looks like this:

```nix
{ ... }: # This is needed! It's a Nix thing.
{
  name = "hello-world";
  version = "0.1.0";
  edition = 2024;
}
```

As you can see, `crate.nix` strongly resembles `Cargo.toml`. This is intentional - Cargo is already really awesome, so much of nixrs is inspired by it. Also like Cargo, you can build your crate with `nixrs build` and run it with `nixrs run`.

nixrs will generate a barebones project for you if you call `nixrs new` or `nixrs init`. It'll also generate a `shell.nix` file, so if you have [direnv](https://direnv.net/) you'll automatically get a [devshell](https://nix.dev/tutorials/first-steps/declarative-shell.html) with your Rust toolchain and any binary dependencies you add with nixrs.



# nixrs API

nixrs is split into two portions - a Nix API, and a Nix Module. The module powers `crate.nix` and the CLI. However, nixrs aims to be very flexible, and there may be some cases where using the CLI doesn't work well for a project - for example, a large multi-language project where the Rust crates are only one portion of the larger codebase.

In a situation like that, you can skip the Nix module and just use the nixrs API directly. The nixrs module intentionally just wraps around the nixrs API, so you won't lose any features by doing this. This allows you to use Nix as a build system for many languages and have your Rust crates just be one portion of the system - handled for you by nixrs.

There aren't many docs written for the nixrs API outside of the nixrs source code. You can see all of nixrs' functions in `nixrs/default.nix`. You can look in `nixrs/config` for an example of using the nixrs API - that portion of the codebase glues the nixrs Nix Module to the nixrs API and calls all the correct functions to build a crate configured with `crate.nix`.

> Note: The nixrs API is currently extremely unstable because nixrs is still very WIP. If you use it, you should probably pin nixrs to a specific Git commit and update carefully.



# Current Limitations

- (wip) nixrs doesn't support depending on Cargo crates
- (wip) nixrs doesn't integrate well with rust-analyzer
	- features specific to rust-analyzer work (e.g. docs on hover, jump to source)
	- compiler features do not (e.g. most compilation warnings/errors)
- nixrs doesn't support crate features
- nixrs cannot download crates from crates.io
- the nixrs CLI doesn't accept flags for running unit tests or building in release mode
	- The current CLI is written in Bash and just doesn't work well; I'm working on my own CLI library for Rust and will rewrite the CLI once it's completed
- nixrs doesn't have any form of workspaces
- nixrs lacks a lot of compilation options that Cargo has
- miri requires special sysroot settings and tries to manage dependencies on its own. As such I haven't yet figured out how to get it to run in a nixrs project.
