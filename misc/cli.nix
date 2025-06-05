# Nix file called by the nixrs CLI to build a crate.

{
  crateRoot, # An absolute path to the root of the nixrs crate we're compiling.
  registries, # Crate registries that nixrs can download crates from.
  pkgs ? import <nixpkgs> { },
}:

(import ../nixrs { inherit registries pkgs; }).compileCrate crateRoot
