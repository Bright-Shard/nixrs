{
  readDir,
  nixrs,
  pkgs,
  lib,
  ...
}:

cratePath:
let
  crateRoot = readDir cratePath;
in
if crateRoot ? "build.nix" then
  import "${cratePath}/build.nix" nixrs
else if crateRoot ? "crate.nix" then
  let
    module = lib.evalModules {
      modules = [
        nixrsWithModule.module
        /${cratePath}/crate.nix
      ];
      specialArgs = {
        inherit pkgs lib nixrs;
      };
    };
    nixrsWithModule = nixrs.withModule cratePath module;
  in
  nixrsWithModule.compileModule
else if crateRoot ? "Cargo.toml" then
  abort "TODO: Cargo crate"
else
  abort "Dependency at `${cratePath}` is supposed to be a crate, but it doesn't have a `Cargo.toml` file nor a `crate.nix` file."
