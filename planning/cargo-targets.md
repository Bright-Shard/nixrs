# Cargo Targets

Cargo has a concept of targets (not target triples) that essentially function as multiple crates within one package. For example, one Cargo package can have both a library and a binary inside it, so you could make a library and then a CLI for using it.

Targets have more features, too. They can be benchmarks or unit tests, and you can change some (but not all) compilation options for just one target.

I have a few problems with Cargo targets, though:
1. They use different names for crate types. rustc's crate types are `lib`, `rlib`, `dylib`, `cdylib`, `staticlib`, `proc-macro`, and `bin`. Cargo's are `lib`, `bin`, `bench`, `test`, and `example`.
2. It's confusingly named because the name is `target` but targets often refer to target *triples*, i.e. a specific platform/host that code is compiled for.
3. It's also confusing because there's now two sets of crate types. But Cargo's crate types don't cover every use case, so you may also have to use rustc's crate types in your `Cargo.toml`.
	- To be fair, Cargo doesn't call these crate types, and they're specified in a different way (e.g. `[[example]]` vs `crate-type = "cdylib"`)
4. Targets let you control *some* compilation settings, but not all. For example, targets can set their crate type, but not change what dependencies the crate needs.
5. Cargo targets only allow one library.

The intent (I believe) is to make it easy to declare things like tests and benchmarks, and give code scopes. `example` targets are only run if you pass Cargo the `--example` flag, and `test` targets are only run with `cargo test`.


# The Problem

nixrs cannot ignore Cargo targets, for two reasons:

1. nixrs needs backwards-compatibility with Cargo. So nixrs must, at the very least, support targets in its internal crate representation.
2. nixrs needs feature-parity with Cargo, and targets undeniably add useful features.

So Cargo targets are problematic because I don't agree with their design for the previously mentioned reasons but must support them and implement an equivalent in nixrs.


# Brainstorming Solutions (Round 1)

## Outputs

I think the simplest approach is to implement a feature-par equivalent of targets in nixrs. Then Cargo targets can be translated into nixrs' equivalent, and nixrs can offer the same features as Cargo.

I believe I'll call nixrs' equivalent `outputs`. This way they can't be confused with target triples, but still have a similar name - they're outputs of the nixrs build system, similar to how targets are goals for Cargo to build.

## No Targets

An alternative approach is to not have targets at all. Cargo already restricts libraries to one per package; with this approach everything else (binaries etc) would also be restricted to one per package.

The upside of this approach is it's dead simple. Crates are one unit of code, there's no weird semi-abstraction layer on top.

However, there are several notable downsides:
1. Tests, benchmarks, and examples all have to explicitly be separate crates now.
	- Examples being standalone crates isn't that bad; honestly they already are in many projects today. Though that may just be so that they can specify additional dependencies, unsure.
	- Could erase the concept of a target, and instead of crates, and allow crates to have tests/benchmarks. That way tests and benchmarks are still treated first-class and easy to add, and there's still no weird package abstraction layer.
2. In some cases it's just useful to have multiple libraries inside one crate.
	- Proc macros require creating a separate crate. This is annoying because you have to create a new folder, with a new package manifest, with separate dependencies, etc.
	- Being able to put multiple libaries in one crate allows you to control all of those libraries from a single manifest file. This reduces boilerplate and friction for developers.
	- On the other hand, allowing multiple libraries in one crate may also create confusingly structured and messy codebases. One library per crate creates an expected project structure that this could violate.
		- There'd also be potentially confusing scenarios like two source files `mod`-ing the same other file because those two files are different libraries in the same crate.
3. Being able to put a library and a binary in one crate can also be nice.
	- Mostly just for reducing boilerplate as mentioned previously.


# Brainstorming Conclusions

1. Cargo targets are imperfect, but add genuinely useful features.
2. Many use cases for targets have been replaced by workspaces.
3. Targets can be nicer than workspaces because multiple crates can be defined in one manifest file, reducing boilerplate and maintenance overhead.

I'm going to proceed with the `Outputs` solution for now; I may iterate more later.


# Crates with Multiple Library Outputs

You can only depend on a specific crate once, because they're imported by name. So if a crate has multiple libraries, some of the libraries will have to have custom names.

It's also probably useful to allow private outputs. For example, proc-macro codegen crates probably aren't meant to be part of a library's public facing API. So a library with a codegen crate would probably find it useful to make the codegen crate only accessible to the library itself and not other crates.

I think the simplest way to do this is to add a `private` flag to output settings. Private outputs can only be built by the current crate and other crates cannot depend on them.
