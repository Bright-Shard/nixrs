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
        description = "Whether or not to enable rust-analyzer support. When enabled, on every build, nixrs will generate a rust-project.json file in the root of your workspace so rust-analyzer can work correctly.";
        type = bool;
        default = true;
      };
    };
  };
}
