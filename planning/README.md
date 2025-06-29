For complicated projects it's helpful to put my ideas into words. Makes my brain slow down and forces me to carefully consider design, use cases, etc.

This folder is entirely dedicated to planning. It's open source so you can read my thoughts, understand my goals, and maybe develop new ideas yourself.


# The Problem

> Why am I making nixrs? What makes it worth all the effort instead of just using something like Cargo?

I often feel like I run into limitations with build systems.

This is similar to the feeling I've gotten from most programming languages. A lot of them have obvious, gaping holes that are annoying to work with. Many of which Rust solves. Rust is not a perfect language; but it is a great one, a language that truly feels like it iterates on all the languages we've used before and works better than any of them. My experience with Python, JavaScript, Java, HTML/CSS, C#, C, C++, Lua, Bash, Nix; and now Rust, tells me this. Rust is truly something special.

However, Rust's build system, Cargo, does *not* give me this same feeling. I've worked (usually limited, but to some degree) with Maven, CMake, Make, Cargo, Pip, Poetry, as well as languages without a build system (Lua, stock JS). None of these programs give me the same feeling that Rust does. They all have limitations or preventable bugs I've personally run into.

Given all of Rust's strengths, I want it to have a better build system. Cargo is *really* good, but it's not as good as Rust. So I briefly tried wrapping Cargo, and made [Bargo](https://github.com/bright-shard/bargo). This was... nearly good enough for my operating system, [bs](https://github.com/bright-shard/bs). But Bargo wasn't really good enough either. It was awkward to use and just patched a couple of features on top of Cargo without fixing underlying issues. So... back to the drawing board.

These are the attributes I love about Rust:
1. Correct: Rust enforces correct code. Memory safety eliminates some 70% of bugs programmers can run into. Rust establishes a few ground rules to make sure your program will work and lets you handle everything else.
2. Scalable: The same language that lets you spawn async background tasks in one line of code will let you embed inline assembly and loosen compiler restrictions in the next. This is why Rust works for everything from operating systems and kernel code to backend servers and (hopefully) GUI.
3. Fast: Don't waste 170 CPU instructions on Python resolving which piece of code to dynamically call for adding two numbers. Rust is fucking fast, so you don't waste time while testing your app for bugs, your laptop keeps its battery longer, and your users don't load for 3 years.

Similarly, a proper build system should be:
1. Correct: Builds should work on anyone's computer without chasing down random dependencies. The build system should provide everything you need, so you don't have to try and create the perfect docker container and ship your machine.
2. Scalable: The build system should offer the easy manifests developers love with Cargo and NPM, where simple dependencies are as easy as `name = version`. But it should also allow you to configure low-level details like which linker you want to use, the executable format of your app, or how to bridge two libraries from different programming languages.
3. Fast: Build times are run times too; it just takes place on your machine instead of your users'. Waiting several seconds to see code feedback in your IDE or to rebuild your app to see simple UI changes is an unacceptable waste of time.


# The Vision

Recently, I discovered [NixOS](https://nixos.org) and [nixpkgs](https://github.com/NixOS/nixpkgs). These *do* give me similar feelings to Rust. They have limitations (especially in the Nix language), but they're flexible and completely solve dependencies.

Right now, Nix is not a build system. It's a language, a package manager, and an operating system. And yet, it does everything a build system can do - it builds code and automatically manages dependencies. Unlike build systems, though, Nix can build code in any language, and guarantees reproducible builds by solving dependencies.

Nix *can* be a build system - but it can go farther than any existing build system. Nix has the power to compile code from any number of unique programming languages, and then bundle that code into a usable app. It can guarantee the app will build on any contributer's computer, because builds are reprodicible, so no need to track down missing dependencies or missing environment variables. And it's powered by a fully-fledged dynamic language, which means you can achieve all of this in normal Nix, no awkward hacks required.

Nix is correct and scalable. Unfortunately, dynamically-typed runtime languages often aren't particularly fast. Modern hardware can tank some of the cost, but eventually I will have to focus on optimising nixrs.

The end goal is for nixrs to inherit reproducible builds from Nix, be specialised so it's easy to use for Rust, and be flexible enough to work for any project.

nixrs should be so flexible that it is complete at its first release. Later updates should not need to add anything to enable new functionality - instead, they should just optimise the existing code, or add syntax sugar so things that were already possible are a little easier to do.


# Rough List of Needed Features

- Download crates from crate repositories (e.g. crates.io)
- Manage the Rust toolchain and be feature-par with rustup
- Integration with rust-analyzer (which normally assumes projects are based on Cargo)
- A simple, declarative manifest like Cargo.toml - this makes it easy for Rust projects to migrate to nixrs and makes nixrs easy to use
- A feature-complete, lower-level API, to allow advanced users to scale easily from the high-level declarative configuration to low-level compiler flags
- Compile times on par with Cargo
- Features on par with Cargo
	- Miri
	- Unit tests
	- Benchmarks
	- Crate dependency management
	- Build scripts
	- Custom subcommands
	- Configurable optimisation levels and targets
	- Some equivalent of Cargo targets
- Post build scripts (these were useful for BS)
- Linker scripts (also useful for BS)
- Completely custom build processes (ie complete control over how a crate is built)
	- Webphishing needs to build to a specialised DLL
	- BS' bootloader has to link code from differing architectures
- Should allow plugins that modify the build process or build manifest
	- For example ROS has custom functions it uses in CMake
- Direct arguments to rustc
- Direct arguments to the linker
- Compatibility with Cargo projects
	- Need to be able to import crates from crates.io
	- Support mixed nixrs & Cargo workspaces?
