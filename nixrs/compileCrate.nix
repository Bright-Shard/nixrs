{
  readDir,
  nixrs,
  pkgs,
  lib,
  ...
}:

{
  crateRoot,
  workspaceCfg ? null,
}:
let
  crateDir = readDir crateRoot;
in
if crateDir ? "build.nix" then
  import "${crateRoot}/build.nix" nixrs
else if crateDir ? "crate.nix" then
  let
    moduleRaw = lib.evalModules {
      modules = [
        nixrsWithModule.module
        "${crateRoot}/crate.nix"
      ];
      specialArgs = {
        inherit pkgs lib nixrs;
      };
    };
    module =
      if workspaceCfg != null then
        moduleRaw
        // {
          config = moduleRaw.config // {
            workspace = workspaceCfg;
          };
        }
      else
        moduleRaw;
    nixrsWithModule = nixrs.withModule crateRoot module;
  in
  nixrsWithModule.compileModule
else if crateDir ? "Cargo.toml" then
  abort "TODO: Compile Cargo crate"
else
  abort "Dependency at `${crateRoot}` is supposed to be a crate, but it doesn't have a `Cargo.toml` file nor a `crate.nix` file."
