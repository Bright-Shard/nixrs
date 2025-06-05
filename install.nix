let
  pkgs = import <nixpkgs> { };
in
pkgs.callPackage ./install.nix { }
