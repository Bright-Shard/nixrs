# nixrs module

This is the core Nix code that powers nixrs - it can generate dependency trees, find the URLs to download crates from, and compile crates. This module doesn't include the higher-level CLI or crate.nix APIs. This is kind of a lower-level API for any build system that doesn't integrate well with crate.nix for whatever reason.
