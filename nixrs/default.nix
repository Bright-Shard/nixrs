{
  registries,
  pkgs ? import <nixpkgs> { },
}:

let
  inherit (builtins) listToAttrs attrNames readDir;
in
let
  nixrs = builtins // {
    inherit pkgs;
    inherit registries;

    lib = pkgs.lib;

    mkType = import ./mkType.nix nixrs;
    compile = import ./compile.nix nixrs;
    dependenciesToLinks = import ./dependencies.nix nixrs;

    types = listToAttrs (
      map (
        file:
        let
          type = import ./types/${file} nixrs;
        in
        {
          name = type.typeName;
          value = type;
        }
      ) (attrNames (readDir ./types))
    );
  };
in
nixrs
