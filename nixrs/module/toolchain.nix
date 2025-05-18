# Toolchain options

{ lib, ... }:

let
  inherit (lib) mkOption;
  inherit (lib.types)
    listOf
    str
    submodule
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
      targets = mkOption {
        description = "Target triples to install in the Rust toolchain.";
        type = listOf str;
        # TODO set default to host target triple
      };
      profile = mkOption {
        description = "The toolchain profile to install.";
        type = str;
        default = "default";
      };
      components = mkOption {
        description = "Components to install in the Rust toolchain.";
        type = listOf str;
      };
    };
  };
}
