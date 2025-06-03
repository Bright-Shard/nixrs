{
  pkgs ? import <nixpkgs> { },
}:

let
  workspaceRoot = ./.;
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
      workspaceRoot
      module;
in

pkgs.mkShell {
  packages = nixrs.shellPackages;
}
