# The bridge between crate.nix and the core nixrs module. This file loads
# crate.nix as a Nix module, then parses any relevant config and passes the
# correct settings to nixrs to compile the Rust crate.

{
  crateRoot, # An absolute path to the root of the nixrs crate we're compiling.
  registries, # Crate registries that nixrs can download crates from.
  pkgs ? import <nixpkgs> { },
}:

let
  nixrs = import ./../nixrs {
    inherit pkgs;
    inherit registries;
  };
  crateModule = pkgs.lib.evalModules {
    modules = [
      ./../crateOptions
      /${crateRoot}/crate.nix
    ];
    specialArgs = {
      inherit pkgs;
      inherit nixrs;
    };
  };
  config = crateModule.config;
  crateStoreRoot = pkgs.lib.fileset.toSource {
    root = crateRoot;
    fileset = crateRoot;
  };
in
# TODO build scripts
nixrs.compile {
  crateName = config.name;
  crateType = "bin"; # TODO support multiple crate types
  rustcPath = config.compiler-options.rustc-path;
  bashPath = "${pkgs.bash}/bin/bash";
  linkerPath = "${pkgs.gcc}/bin/cc"; # TODO allow custom linkers
  edition = config.edition;
  links = nixrs.dependenciesToLinks config.dependencies;
  target = "x86_64-unknown-linux-gnu"; # TODO use system target & allow override
  src = "${crateStoreRoot}/src/main.rs"; # TODO
}
