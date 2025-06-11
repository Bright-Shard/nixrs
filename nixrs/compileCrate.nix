{
  readDir,
  nixrs,
  pkgs,
  lib,
  nixty,
  ...
}:

let
  argsTy =
    with nixty.prelude;
    newType {
      name = "compile-crate-args";
      def = {
        crateRoot = oneOfTy [
          path
          str
        ];
        workspaceCfg = nullOr set;
      };
    };
in

argsRaw:
let
  args = argsTy argsRaw;
  crateDir = readDir args.crateRoot;
in
if crateDir ? "build.nix" then
  import "${args.crateRoot}/build.nix" nixrs
else if crateDir ? "crate.nix" then
  let
    moduleRaw = lib.evalModules {
      modules = [
        nixrsWithModule.module
        "${args.crateRoot}/crate.nix"
      ];
      specialArgs = {
        inherit pkgs lib nixrs;
      };
    };
    module =
      if args.workspaceCfg != null then
        moduleRaw
        // {
          config = moduleRaw.config // {
            workspace = args.workspaceCfg;
          };
        }
      else
        moduleRaw;
    nixrsWithModule = nixrs.withModule {
      workspaceRoot = args.crateRoot;
      inherit module nixrs;
    };
  in
  nixrsWithModule.compileModule
else if crateDir ? "Cargo.toml" then
  abort "TODO: Compile Cargo crate"
else
  abort "Dependency at `${args.crateRoot}` is supposed to be a crate, but it doesn't have a `Cargo.toml` file nor a `crate.nix` file."
