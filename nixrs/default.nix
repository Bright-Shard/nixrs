{
  registries ? { },
  pkgs ? import <nixpkgs> { },
}:

let
  inherit (builtins) listToAttrs attrNames readDir;
  nixrs = builtins // rec {
    #
    # imports
    #

    inherit pkgs;
    lib = pkgs.lib;
    inherit registries;
    nixty = import ../nixty;

    #
    # nixrs' custom nixty types
    #

    # A set of every nixty type nixrs uses.
    types = listToAttrs (
      map (
        file:
        let
          type = import ./types/${file} nixrs;
        in
        {
          name = type.__nixty;
          value = type;
        }
      ) (attrNames (readDir ./types))
    );

    #
    # utilities
    #

    # Convert a Nix target name to a Rust target triple.
    nixTargetToRustTarget = target: (lib.systems.elaborate target).rust.rustcTarget;
    # The Rust target triple for the current system.
    currentSystemRust = nixTargetToRustTarget builtins.currentSystem;
    # Download a file with a known SHA-256 hash.
    download = import ./download.nix nixrs;

    #
    # nixrs API
    #

    inherit nixrs;
    # Function to build a nixrs or Cargo crate. Takes the path of the crate to
    # build, and optionally workspace settings for the crate.
    compileCrate = import ./compileCrate.nix nixrs;
    # Nix wrapper for rustc.
    rustc = import ./rustc.nix nixrs;
    # Download a crate from a registry like crates.io.
    fetchCrate = import ./fetchCrate.nix nixrs;
    # Convert a list of dependencies to a list of compilation settings that
    # can be passed to nixrs.compile.
    dependenciesToSettings = import ./dependencies.nix nixrs;
    # Download and install a specific Rust toolchain.
    installToolchain = import ./installToolchain.nix nixrs;
    # Load the nixrs Nix Module. Note that this is a function; it takes one
    # argument, which is the root folder of the crate to build (i.e. the folder
    # that `crate.nix` is inside). This is because the module needs to know
    # where the Rust code is in order to set proper default settings and
    # compile the code.
    withModule = import ../module;
    # All the Rust editions that have been published to date.
    VALID_RUST_EDITIONS = [
      2015
      2018
      2021
      2024
    ];
    # Same as above, as strings instead of integers.
    VALID_RUST_EDITIONS_STR = map (edition: toString edition) VALID_RUST_EDITIONS;
    # nixrs packaged so it can be installed with Nix
    # Can install with `pkgs.callPackage nixrs.package {}`
    package = import ../package.nix;
  };
in
nixrs
