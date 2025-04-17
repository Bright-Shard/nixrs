{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  name = "nixrs-dev-shell";
  packages = with pkgs; [
    rustup
  ];
}
