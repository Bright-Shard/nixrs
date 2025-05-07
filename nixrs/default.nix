{
  crateRoot,
  pkgs ? import <nixpkgs> { },
}:

let
  lib = pkgs.lib;
  module = pkgs.lib.evalModules {
    modules = [
      ./options.nix
      /${crateRoot}/crate.nix
    ];
    specialArgs = { inherit pkgs; };
  };
  config = module.config;
  crateStoreRoot = lib.fileset.toSource {
    root = crateRoot;
    fileset = crateRoot;
  };
in
import ./buildCrate.nix {
  crateName = config.name;
  crateType = "bin"; # TODO support multiple crate types
  rustcPath = config.compiler-options.rustc-path;
  bashPath = "${pkgs.bash}/bin/bash";
  linkerPath = "${pkgs.gcc}/bin/cc"; # TODO allow custom linkers
  edition = config.edition;
  links = [ ]; # TODO dependencies
  target = "x86_64-unknown-linux-gnu"; # TODO use system target & allow override
  src = "${crateStoreRoot}/src/main.rs"; # TODO
}
