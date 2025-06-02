{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  name = "nixrs-dev-shell";

  packages = with pkgs; [
    git
    (callPackage ./package.nix { })
  ];
}
