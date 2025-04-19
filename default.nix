{ pkgs }:

pkgs.writeShellScriptBin "nixrs" (builtins.readFile ./cli.sh)
