{
  registries ? { },
  pkgs ? import <nixpkgs> { },
}:

let
  nixrs = builtins // rec {
    #
    # imports
    #

    inherit pkgs;
    lib = pkgs.lib;
    inherit registries;

    #
    # typing
    #

    # The typing system nixrs uses.
    nixty = import ../nixty;
    # A set of every nixty type nixrs uses.
    types = import ./types nixrs;

    #
    # utilities
    #

    # Convert a Nix target name to a Rust target triple.
    nix-target-to-rust-target = target: (lib.systems.elaborate target).rust.rustcTarget;
    # Download a file with a known SHA-256 hash.
    download = import ./download.nix nixrs;
    # Provide a fallback value in case one value is null.
    fallback = val1: val2: if val1 != null then val1 else val2;

    #
    # consts
    #

    # The Rust target triple for the current system.
    CURRENT-SYSTEM-RUST = nix-target-to-rust-target builtins.currentSystem;
    # All the Rust editions that have been published to date.
    VALID-RUST-EDITIONS = [
      2015
      2018
      2021
      2024
    ];
    # Same as above, as strings instead of integers.
    VALID-RUST-EDITIONS-STR = map (edition: toString edition) VALID-RUST-EDITIONS;
    # The types of crates that rustc can compile.
    VALID-CRATE-TYPES = [
      "bin"
      "lib"
      "rlib"
      "dylib"
      "cdylib"
      "staticlib"
      "proc-macro"
    ];
    # The types of native libraries that rustc can link against.
    NATIVE-LIBRARY-TYPES = [
      "static"
      "framework"
      "dylib"
    ];
    # The types of search paths rustc uses.
    SEARCH-PATH-TYPES = [
      "dependency"
      "crate"
      "native"
      "framework"
      "all"
    ];

    #
    # nixrs API
    #

    inherit nixrs;
    # Nix wrapper for rustc.
    rustc = import ./rustc.nix nixrs;
    # Converts a Cargo or nixrs Nix Module crate to nixrs' internal `crate`
    # type.
    parse-crate = import ./parse-crate nixrs;
    # Converts a nixrs Nix Module into nixrs' `crate` type. This is a function
    # that takes a path to the root of the crate - the parent folder of the
    # `crate.nix` file.
    parse-nixrs-module = import ./parse-nixrs-module.nix nixrs;
    # Generates a dependency tree for a crate.
    gen-dep-tree = import ./gen-dep-tree.nix nixrs;
    # Download a crate from a registry like crates.io. Currently incomplete.
    fetch-crate = import ./fetch-crate.nix nixrs;
    # Download and install a specific Rust toolchain.
    #
    # Returns an attribute set where every key is a target triple that
    # toolchain components were installed for, and every value is a nested
    # attribute set. That nested attribute set contains a SYSROOT key, which
    # stores the Nix store path to the sysroot for that target triple, plus
    # keys for every installed component that store the Nix store path where
    # that component was installed by itself.
    #
    # ```nix
    # {
    #   some-target-triple = {
    #     SYSROOT = path/to/sysroot/with/all/components;
    #     component1 = path/to/component;
    #     component2 = path/to/component;
    #   };
    # }
    # ```
    install-toolchain = import ./install-toolchain.nix nixrs;
    # Load the nixrs Nix Module. Note that this is a function; it takes one
    # argument, which is the root folder of the crate to build (i.e. the folder
    # that `crate.nix` is inside). This is because the module needs to know
    # where the Rust code is in order to set proper default settings and
    # compile the code.
    with-module = import ../module;
    # nixrs packaged so it can be installed with Nix.
    #
    # For example, you can install nixrs with:
    # `pkgs.callPackage nixrs.package {}`
    package = import ../package.nix;
  };
in
nixrs
