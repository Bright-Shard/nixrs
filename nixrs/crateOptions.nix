{ lib, ... }:
with lib;
with lib.types;
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
      description = "The crate's version. This should follow semantic versioning.";
      # TODO validate as semantic version
      type = str;
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
      # TODO validate as semantic version
      type = nullOr str;
      default = null;
    };

    meta = mkOption {
      description = "Crate metadata.";
      type = submodule {
        options = {
          authors = mkOption {
            description = "The crate authors.";
            type = listOf str;
          };
          documentation = mkOption {
            description = "A link to the crate's docs.";
            # TODO validate as URL
            type = nullOr str;
            default = null;
          };
          readme = mkOption {
            description = "The path to the crate's README file.";
            type = path;
            default = /${crateRoot}/README.md;
          };
          homepage = mkOption {
            description = "A link to the crate's homepage.";
            # TODO validate as URL
            type = nullOr str;
            default = null;
          };
          repository = mkOption {
            description = "A link to the crate's source code repository.";
            # TODO validate as URL
            type = nullOr str;
            default = null;
          };
        };
      };
    };

    license = mkOption { };
    license-file = mkOption { };

    dependencies = mkOption {
      description = "Any code you need to build or run this crate.";
      type = submodule {
        options = {
          bins = listOf oneOf [ pkg ];
        };
      };
    };

    compileOptions = mkOption {
      description = "Extra options to pass to the Rust compiler.";
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
    };

    cargo-compatibility = mkOption {
      description = "Whether or not to generate a Cargo.toml file, to make this project compatible with Cargo. Note that when Cargo compatibility is enabled, not all nixrs features will be available, because some of its features do not exist in Cargo.";
      type = bool;
      default = false;
    };

    rust-analyzer = mkOption {
      description = "rust-analyzer configuration.";
      type = submodule {
        options = {
          enable = mkOption {
            description = "Whether or not to enable rust-analyzer support.";
            type = bool;
            default = true;
          };
        };
      };
    };
  };
}
