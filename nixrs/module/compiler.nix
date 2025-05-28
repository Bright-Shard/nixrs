# Compiler options

{
  lib,
  crateRoot,
  ...
}:

let
  inherit (lib) mkOption;
  inherit (lib.types)
    str
    submodule
    nullOr
    path
    ;
in

mkOption {
  description = "Extra options to pass to the Rust compiler.";
  default = { };
  type = submodule {
    options = {
      target-triple = mkOption {
        description = "The target triple to compile this crate for.";
        type = str;
      };
      nightly-features = mkOption {
        description = "Unstable compiler features to enable.";
        type = nullOr str;
      };
      linker-script = mkOption {
        description = "A script to pass to the linker when linking this crate.";
        type = nullOr str;
      };
      prebuild-script = mkOption {
        description = "A Rust script to run before the crate is built.";
        type = path;
        default = /${crateRoot}/build.rs;
      };
      postbuild-script = mkOption {
        description = "A Rust script to run after the crate is built.";
        type = path;
        default = /${crateRoot}/post-build.rs;
      };
    };
  };
}
