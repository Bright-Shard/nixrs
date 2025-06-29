# nixrs Build Process

Rough outline of the build process:
- If there's no lock file:
	- Parse manifest of the root crate
	- Recursively find dependencies and dependencies of those dependencies
	- Unify features and crate versions to reduce number of compilation jobs - this will be the final dependency tree
		- Will need to generate one tree for every build scope
	- Generate lock file with dependency tree
- Use dep tree from lock file
- Compile pre-build script and run
- Compile crate
- Compile post-build script and run
- Post-compilation steps
	- If testing, run test suite
	- If running, run binary
	- If building a workspace, generate `rust-project.json`


# Lock File

In most build systems, the lock file just serves as a way to rebuild with the exact same dependencies as a previous build - Cargo does this for example. For nixrs, though, the lock file will probably also serve as an optimisation.

Nix is a dynamically-typed runtime language. I don't have high hopes for its performance. It will probably take *several* times longer for nixrs to solve a dependency tree than for Cargo to solve the same tree.

This performance matters because, unfortunate as it is, many Rust codebases for large projects can pull in 1k+ dependencies. If nixrs is wasting time on every single build solving the build's dependency tree, this is an objective waste of developers' time. Caching the dependency tree in a lock file and re-reading it on the next build will be faster.

This will likely differ from Cargo because (afaik) Cargo only re-uses the lock file if you pass the `--locked` flag.


# Parsing Crates

nixrs needs to convert every crate in a dependency tree to its internal crate format. However, the crate type alone doesn't store enough information for dependency resolution - dependencies will also need to store:

1. Which output they depend on. nixrs allows crates to have multiple outputs (see [cargo-targets.md](cargo-targets.md)), including multiple libraries in one crate. If no output is specified the default is `lib`.
2. The range of acceptable crate versions for the dependency. This allows unifying crates so they're only built once for two crates that depend on similar versions of the same crate.
3. The features this dependency enables on the crate. This allows for feature unification so the crate is only built once with all the needed features from all crates.

All of this information is dependency-specific, not crate-specific; that is, these pieces of data can change between two crates that depend on the exact same version of the exact same crate. So nixrs will need a dependency type that stores all of this information and points to the crate table.

It may be worth having a "crate cache" that maps a crate name, exact version, and list of enabled features to crate tables. This way if two crates depend on the exact same version of a crate the crate's manifest is only parsed once. Actually, this is probably necessary - otherwise crates like winit (that pull in hundreds of deps) will be processed multiple times even if the exact same version is depended upon.

Unfortunately, I don't think the cache can store any information if crate versions are even slightly different or two crates enable different features, because if either of those change the crates' dependencies can also change.


# Cyclical Dependencies

Nix has built-in infinite recursion detection, so I shouldn't need to add any special code to prevent an infinite loop from cyclical dependencies. However, the error message from infinitely recursing will likely not be user-friendly, so I probably need to figure out a way to suggest to the user that there's a dependency cycle.

So... before tackling this problem I should get nixrs in a state where it can actually build crates and handle dependencies. Then I can create several test scenarios with cyclical dependencies and see what happens.

I'll also need to see what happens if two crates depend on the exact same version of some other crate, and make sure that doesn't trigger the cyclical dependency error.


# ~~Generating~~ Optimising the Dependency Tree

nixrs will need to generate a final dependency tree that can compile the root crate but optimises the number of compilation steps required with feature unification and version unification.

We already have a rough dependency tree from parsing all crates earlier, but this tree isn't optimised and will likely result in recompiling the same crates several times. So, what we need is a way to efficiently find unifiable dependencies in that tree and combine them.

Because Nix is a runtime language, I don't want to iterate over the dependency tree more than necessary, because I think that'd add a lot of overhead. So it's not worth performing another scan of the tree just to optimise it. Instead, we should build caches of potentially-optimisable dependencies while building the dependency tree. Then in this step we can check those caches and modify the tree as necessary to optimise it.

For example, while building the dependency tree we should build a cache that maps crate names to dependents. Then in the optimisation step we can iterate through this cache and find all the crates that depend on the same crate, then try to merge the dependencies' versions and features if possible.

One problem with this cache is there could be name collisions; for example, if a local crate depends on another local crate named `syn` but then a crates.io crate depends on the crates.io `syn` crate. I'll need to check crate targets and the source of those targets to make sure crates are the same before unifying them.

Another problem is that Nix is functional, so we cannot simply reassign dependencies in the dependency tree. We instead have to build an entirely new tree with the unified dependencies. I'll need to find an optimised way to handle this.

The final dependency tree can be dumped to a lock file by simply serializing it to JSON with `builtins.toJSON`.


# Compilation

nixrs will essentially just need to convert the dependency tree into a derivation tree. The root crate will be a derivation that depends on the derivations of its dependencies, which depend on the derivations of their dependencies, and so on.

Nix should then automatically handle parallelization.
