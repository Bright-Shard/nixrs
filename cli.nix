# Nix file called by the nixrs CLI to build a crate.

{
  crateRoot, # An absolute path to the root of the nixrs crate we're compiling.
  registries, # Crate registries that nixrs can download crates from.
  pkgs ? import <nixpkgs> { },
}:

let
  inherit (builtins) readDir;

  nixrs =
    (import ./nixrs {
      inherit pkgs;
      inherit registries;
    }).withModule
      crateRoot
      module;
  module = pkgs.lib.evalModules {
    modules = [
      nixrs.module
      /${crateRoot}/crate.nix
    ];
    specialArgs = {
      inherit pkgs;
      inherit (pkgs) lib;
      inherit nixrs;
    };
  };
in
if (readDir crateRoot) ? "build.nix" then
  import /${crateRoot}/build.nix nixrs
else
  nixrs.buildModule
