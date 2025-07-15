{
  pkgs,
  lib,
  nixty,
  nixrs,
  types,
  readDir,
  addErrorContext,
  ...
}:

rec {
  # Parses a nixrs Nix Module to nixrs' `crate` type.
  #
  # This function parses the raw module. You may want to use `nixrs-crate` below
  # instead, which loads the `crate.nix` file and parses the module from there.
  nixrs-module = import ./nixrs-module.nix nixrs;
  # Loads a crate manifest (e.g. `crate.nix`) and parses the Nix Module in it
  # with `nixrs-module`.
  #
  # This function is helpful because it handles loading the Nix Module from the
  # manifest file. But if you already have the module you can instead parse it
  # with `nixrs-module` above.
  nixrs-crate =
    args-raw:
    let
      args-ty =
        with nixty.prelude;
        newType {
          name = "nixrs-parseNixrsCrate-args";
          def = {
            # Root of the nixrs crate.
            crate-root = oneOfTy [
              str
              path
            ];
            # Path from the root of the crate to the crate manifest file - the
            # Nix file that actually defines the Nix Module.
            manifest-path = withDefault "crate.nix" str;
            # Additional special args to pass to the Nix Module.
            special-args = withDefault { } set;
            # Which profile to build with.
            profile = nullOr str;
          };
        };
      args = args-ty args-raw;
    in
    let
      module = lib.evalModules {
        modules = [
          nixrs-with-module.module
          "${args.crate-root}/${args.manifest-path}"
        ];
        specialArgs = {
          inherit pkgs lib nixrs;
        } // args.special-args;
      };
      nixrs-with-module = nixrs.with-module {
        inherit (args) crate-root;
        inherit module nixrs;
      };
    in
    nixrs-module {
      inherit (args) profile;
      module = nixrs-with-module;
    };
  # Parses a `Cargo.toml` file to nixrs' internal `crate` type.
  cargo-crate = abort "todo: Cargo crates";

  # Takes a path to a custom, nixrs, or Cargo crate and parses it appropriately.
  __functor =
    self: args-raw:
    let
      args-ty =
        with nixty.prelude;
        newType {
          name = "nixrs-parseCrate-args";
          def = {
            # Path to the crate's root folder.
            crate-root = oneOfTy [
              path
              str
            ];
            # Crate profile to build.
            profile = nullOr str;
          };
        };
      args = args-ty args-raw;
    in
    let
      inherit (types) crate;
      crate-dir = readDir args.crate-root;
    in
    if crate-dir ? "custom-crate.nix" then
      addErrorContext "While evaluating the custom crate definition at `${args.crate-root}/custom-crate.nix`..." (
        crate (import "${args.crate-root}/custom-crate.nix" nixrs)
      )
    else if crate-dir ? "crate.nix" then
      nixrs-crate { inherit (args) crate-root profile; }
    else if crate-dir ? "Cargo.toml" then
      cargo-crate crate-dir
    else
      abort "crate2nixrs: Crate at `${args.crate-root}` doesn't have a `Cargo.toml` file nor a `crate.nix` file, cannot build.";
}
