# Dev Environment vs Package Environment

From @Ericson2314 in https://github.com/rust-lang/rfcs/pull/1956#issuecomment-290296310:

> @withoutboats reading over your written motivation in response to @eternaleye's points, I think I am noticing something that might be useful. Crucially there is a tension between describing a development environment for the library, and packaging a library for reuse. In the former case, as with a binary, the Cargo file is the root crate in the dependency dag, and thus we should be pretty lax about what is allowed so as not to get in the developer's way. In the latter case however, we have to consider the needs of downstream developers, who need not concern themselves with the idiosyncrasies of upstream developers. For their sake, we should really cramp down on what libraries are allowed to do to enforce consistency / best practices.

This is a problem I was thinking of as well, but they put it really well so I'm including their quote and borrowing their terminology.

In devtime, it's important for developers to have complete control over the developer environment. However, for the purposes of then packaging and distributing their library, it's not clear how much control they should have.

Here's an example: nixrs allows specifying which Rust toolchain a specific project uses. But this setting shouldn't be inherited by downstream dependencies. Otherwise, an app might set their crate to use the nightly toolchain, but import a crate that uses the stable toolchain, and now the developer has to download two toolchains to build their project - not to mention the Rust compiler versions would probably be incompatible.

nixrs intends to allow developers to have a lot more control over their project - toolchain versions, components, unstable compiler features, etc. Therefore nixrs needs to make clear distinctions between what settings a developer can control that only influence their local development (workspace settings) and what settings a developer can control that also influence downstream code (package settings).
