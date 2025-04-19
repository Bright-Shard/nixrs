{ crateRoot, ... }:

let
  pkgs = import <nixpkgs> { };
  lib = pkgs.lib;
  module = pkgs.lib.evalModules {
    modules = [
      ./crateOptions.nix
      ./workspaceOptions.nix

      /${crateRoot}/crate.nix
    ];
  };
  config = module.config;
in
(import ./buildCrate.nix {
  crateName = config.name;
  crateType = "bin"; # TODO
  rustcPath = config.rustc-path;
  linkerPath = "${pkgs.gcc}/bin/cc"; # TODO allow custom linkers
  edition = config.edition;
  deps = [ ]; # TODO support dependencies
  target = "x86_64-unknown-linux-gnu"; # TODO use system target & allow override
  src = lib.fileset.toSource {
    root = crateRoot;
    fileset = crateRoot;
  };
})
