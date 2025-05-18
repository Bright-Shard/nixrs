{
  crateRoot, # An absolute path to the root of the nixrs crate we're compiling.
  registries, # Crate registries that nixrs can download crates from.
  pkgs ? import <nixpkgs> { },
}:

let
  nixrs = import ./nixrs {
    inherit pkgs;
    inherit registries;
  };
  module = pkgs.lib.evalModules {
    modules = [
      (nixrs.module crateRoot)
      /${crateRoot}/crate.nix
    ];
    specialArgs = {
      inherit pkgs;
      inherit nixrs;
    };
  };
in
nixrs.buildConfig module.config crateRoot
