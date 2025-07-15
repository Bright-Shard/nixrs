args:

let
  nixrs = args.nixrs // {
    inherit types;
  };
  types = {
    # nixrs' internal representation of a crate. It's agnostic from any one
    # package format, so it can compile both Cargo packages and nixrs Nix
    # Modules.
    crate = import ./crate.nix nixrs;
    # A crate dependency.
    dependency = import ./dependency.nix nixrs;
    # A semantic version. The type itself only stores the major, minor, and
    # patch version numbers, but it has a `from-string` method that allows
    # converting from traditional semantic version strings: https://semver.org
    semantic-version = import ./semantic-version.nix nixrs;
    # A dependency version specifier. The type itself only stores the minimum
    # and maximum supported versions of a crate, but it has a `from-string`
    # method that allows converting from Cargo version specifiers:
    # https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html#version-requirement-syntax
    dependency-version = import ./dependency-version.nix nixrs;
    # Types that map directly to rust-analyzer's `rust-project.json` schema:
    # https://rust-analyzer.github.io/book/non_cargo_based_projects.html
    #
    # You can convert the type to JSON with `rust-analyzer.serialise val`.
    rust-analyzer = import ./rust-analyzer.nix nixrs;
    # Arguments passed to `nixrs.rustc`.
    rustc-args = import ./rustc-args.nix nixrs;
  };
in
types
