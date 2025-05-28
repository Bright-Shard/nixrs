# Toolchain options

{ lib, ... }:

let
  inherit (lib) mkOption;
  inherit (lib.types)
    listOf
    str
    submodule
    nullOr
    attrsOf
    bool
    ;
in

mkOption {
  description = "Options for the Rust toolchain to build this crate with.";
  default = { };
  type = submodule {
    options = {
      channel = mkOption {
        description = "The Rust channel to install this toolchain from.";
        type = str;
        default = "stable";
      };
      date = mkOption {
        description = "Install the channel published on a specific date.";
        type = nullOr str;
        default = null;
      };
      profile = mkOption {
        description = "The toolchain profile to install. This is the same as rustup profiles, plus a special `nixrs-default` profile that has sensible defaults for nixrs in particular.";
        type = nullOr str;
        default = "nixrs-default";
      };
      components = mkOption {
        description = "Components to install in the Rust toolchain.";
        type = listOf str;
        default = [ ];
      };
      custom-target-components = mkOption {
        description = ''Additional components to install for foreign targets. The format is `<target-triple> = [ "component1" "component2" ]`.'';
        type = attrsOf (listOf str);
        default = { };
      };
      prevent-gc = mkOption {
        description = ''
          Creates a symlink to the Rust toolchain in the `target` folder after compiling this crate.

          That symlink makes Nix see the Rust toolchain as used, so running `nix-store --gc` won't delete the toolchain as long as you don't delete the `target` folder.

          You probably want to leave this on. If you disable this option, Nix will (correctly) infer that the Rust toolchain used to compile this crate is a build-time dependency and isn't needed for the crate to run, so it will garbage collect and delete the toolchain if you run `nix-store --gc`. That means you will have to redownload the entire toolchain the next time you build the crate.
        '';
        type = bool;
        default = true;
      };
    };
  };
}
