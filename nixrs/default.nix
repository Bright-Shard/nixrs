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

    #
    # nixrs internal type system
    #

    # Function for defining a new type.
    mkType = import ./mkType.nix nixrs;
    # A set of all the types nixrs defines.
    types = listToAttrs (
      map (
        file:
        let
          type = import ./types/${file} nixrs;
        in
        {
          name = type.typeName;
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
    # Function to build a nixrs or Cargo crate. Simply takes the path to the
    # crate to build.
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
    #
    # This function returns the `nixrs` set with the additional keys defined in
    # `nixrsModule` below.
    withModule = nixrsModule;
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
  nixrsModule =
    workspaceRoot: module:
    let
      nixrsWithModule =
        nixrs
        // (
          let
            nixrs = nixrsWithModule;
          in
          {
            inherit nixrs;
            inherit workspaceRoot;
            inherit (module) config;

            # Custom option types used by the nixrs Nix Module.
            optionTypes = import ./moduleOptionTypes.nix nixrs;
            # The actual Nix module. Can be imported as a submodule.
            module = import ./module nixrs;
            # Path to the toolchain installed by nixrs
            toolchain = nixrs.installToolchain {
              inherit (module.config.toolchain)
                channel
                date
                profile
                components
                ;
              customTargetComponents = module.config.toolchain.custom-target-components;
            };
            # Takes a Nix module that sets nixrs' options, then
            # compiles the Rust project accordingly with nixrs' API.
            compileModule = import ./config/compile.nix nixrs;
            # Packages to add to a devshell for a nixrs project.
            shellPackages = import ./config/shellPackages.nix nixrs;
            # Converts an attribute set of dependencies to a list of
            # compilation settings.
            dependenciesToCompilationSettings = import ./config/depsToCompSettings.nix nixrs;
          }
        );
    in
    nixrsWithModule;

in
nixrs
