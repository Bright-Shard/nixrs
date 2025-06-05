{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  name = "nixrs-dev-shell";

  packages = with pkgs; [
    git
    ./. # the bin folder will get added to PATH
  ];
}
