{
  lib,
  ...
}@inputs:

crateRoot:

let
  nixrs = inputs // {
    inherit crateRoot;
    optionTypes = import ./optionTypes.nix nixrs;
  };

  inherit (lib) mkOption;
  inherit (lib.types)
    nullOr
    str
    bool
    enum
    attrsOf
    ;
  inherit (nixrs.optionTypes)
    semanticVersion
    dependency
    ;
in

{
  options = {
    name = mkOption {
      description = "The crate's name.";
      type = str;
    };
    description = mkOption {
      description = "A description of the crate.";
      type = str;
      default = "";
    };
    version = mkOption {
      description = "The crate's version.";
      type = semanticVersion;
    };

    edition = mkOption {
      description = "The Rust edition this crate uses.";
      type = enum [
        2015
        2018
        2021
        2024
      ];
    };
    rust-version = mkOption {
      description = "The crate's MSRV (Minimum Supported Rust Version).";
      type = nullOr semanticVersion;
      default = null;
    };

    meta = import ./meta.nix nixrs;

    license = mkOption { };
    license-file = mkOption { };

    build-dependencies = mkOption {
      description = "Any programs or libraries that are only needed while compiling this crate.";
      default = { };
      type = attrsOf dependency;
    };
    dev-dependencies = mkOption {
      description = "Any programs or libraries that are only needed while compiling, testing, or benchmarking this crate.";
      default = { };
      type = attrsOf dependency;
    };
    dependencies = mkOption {
      description = "Any programs or libraries that this crate needs to run.";
      default = { };
      type = attrsOf dependency;
    };

    toolchain-options = import ./toolchain.nix nixrs;

    compiler-options = import ./compiler.nix nixrs;

    cargo-compatibility = mkOption {
      description = "Whether or not to generate a Cargo.toml file, to make this project compatible with Cargo. Note that when Cargo compatibility is enabled, not all nixrs features will be available, because some of its features do not exist in Cargo.";
      type = bool;
      default = false;
    };

    rust-analyzer = import ./rustAnalyzer.nix nixrs;
  };
}
