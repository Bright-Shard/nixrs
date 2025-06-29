{
  lib,
  option-types,
  nixrs,
  VALID-RUST-EDITIONS,
  VALID-CRATE-TYPES,
  ...
}:

let
  inherit (lib) mkOption;
  inherit (lib.types)
    path
    str
    bool
    enum
    submodule
    nullOr
    attrsOf
    listOf
    oneOf
    ;
  inherit (option-types)
    semantic-version
    dependency
    ;

  toolchain-settings = import ./toolchain.nix nixrs;
in

{
  options = rec {
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
      type = semantic-version;
    };
    edition = mkOption {
      description = "The Rust edition this crate uses.";
      type = enum VALID-RUST-EDITIONS;
    };
    features = mkOption {
      description = "Crate features for conditional compilation.";
      type = attrsOf (listOf str);
      default = {
        default = [ ];
      };
    };

    meta = import ./meta.nix nixrs;

    # Global dependencies - added for all outputs, unless overridden.
    dependencies = mkOption {
      description = "Any programs or libraries that this crate needs to run.";
      type = attrsOf dependency;
      default = { };
    };

    # Global compilation settings - set for all outputs, unless overridden.
    compilation = {
      target-triple = mkOption {
        description = "Compile this crate for a specific target triple, instead of the host target triple.";
        type = nullOr str;
        default = null;
      };
    };

    outputs = mkOption {
      description = ''
        Outputs are individual crates within this package that nixrs can build. Each output has a name and can override default package settings, such as dependencies or compilation settings.

        There are a few special outputs:
        - `lib`: The default output used when this package is used as a dependency.
        - `bin`: The default output used when this package is built as a program.
        - `prebuild`: The output that's built and run as a prebuild script.
        - `postbuild`: The output that's built and run as a postbuild script.

        nixrs will automatically add outputs in the following scenarios:
        - `lib`: Added automatically if your package has a `src/lib.rs` file.
        - `bin`: Added automatically if your package has a `src/main.rs` file.
        - `prebuild`: Added automatically if your package has a `prebuild.rs` file.
        - `postbuild`: Added automatically if your package has a `postbuild.rs` file.

        You can still configure any of those outputs here as normal.
      '';
      type = attrsOf (submodule {
        options = {
          source = path;
          inherit dependencies;
          compilation = compilation // {
            crate-type = mkOption {
              description = "The crate type rustc will build this output as. You may specify one or multiple crate types.";
              type = oneOf [
                (listOf VALID-CRATE-TYPES)
                (enum VALID-CRATE-TYPES)
              ];
              default = "bin";
            };
          };
        };
      });
      default = { };
    };

    # Local settings that only affect your developer environment. None of these
    # settings are used when your crate is imported as a dependency.
    dev-env = {
      toolchain = toolchain-settings;
      rust-analyzer = {
        enable = mkOption {
          description = "Whether or not to enable rust-analyzer support. When enabled, on every build, nixrs will generate a rust-project.json file so rust-analyzer can work correctly.";
          type = bool;
          default = true;
        };
      };
    };
  };
}
