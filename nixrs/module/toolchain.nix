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
        description = "The toolchain profile to install.";
        type = nullOr str;
        default = "default";
      };
      components = mkOption {
        description = "Components to install in the Rust toolchain.";
        type = listOf str;
        default = [ ];
      };
      customTargetComponents = mkOption {
        description = ''Additional components to install for foreign targets. The format is `<target-triple> = [ "component1" "component2" ]`.'';
        type = attrsOf (listOf str);
        default = { };
      };
    };
  };
}
