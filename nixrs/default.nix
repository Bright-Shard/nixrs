{
  registries,
  pkgs ? import <nixpkgs> { },
}:

let
  inherit (builtins) listToAttrs attrNames readDir;
  nixrs = builtins // rec {
    # Attribute set
    inherit pkgs;
    # Attribute set
    inherit registries;

    # Attribute set
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

    # Attribute set
    lib = pkgs.lib;

    nixTargetToRustTarget = target: (lib.systems.elaborate target).rust.rustcTarget;
    currentSystemRust = nixTargetToRustTarget builtins.currentSystem;

    download = import ./download.nix nixrs;

    installToolchain = import ./installToolchain.nix nixrs;

    # Function
    mkType = import ./mkType.nix nixrs;
    # Function
    compile = import ./compile.nix nixrs;
    # Function
    fetchCrate = import ./fetchCrate.nix nixrs;
    # Function
    dependenciesToSettings = import ./dependencies.nix nixrs;

    # Function (crateRoot) -> module
    module = import ./module nixrs;
    # Function (config) -> (crateRoot) -> derivation
    buildConfig = import ./config nixrs;
    # Function (dependenciesConfig) -> [dependency]
    dependencyConfigToList = import ./config/dependencies.nix nixrs;
  };
in
nixrs
