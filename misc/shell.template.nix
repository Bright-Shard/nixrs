{
  pkgs ? import <nixpkgs> { },
}:

let
  crateRoot = ./.;
  module = pkgs.lib.evalModules {
    modules = [
      nixrs.module
      ./crate.nix
    ];
    specialArgs = {
      inherit pkgs nixrs;
      inherit (pkgs) lib;
    };
  };
  nixrs =
    (import "${
      builtins.fetchGit {
        url = "https://github.com/bright-shard/nixrs.git";
        ref = "main";
      }
    }/nixrs" { }).withModule
      crateRoot
      module;
in

pkgs.mkShell {
  packages = nixrs.shellPackages;
}
