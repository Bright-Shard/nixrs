# Rust-Analyzer options

{
  lib,
  ...
}:

let
  inherit (lib) mkOption;
  inherit (lib.types)
    submodule
    bool
    ;
in

mkOption {
  description = "rust-analyzer configuration.";
  default = { };
  type = submodule {
    options = {
      enable = mkOption {
        description = "Whether or not to enable rust-analyzer support.";
        type = bool;
        default = true;
      };
    };
  };
}
