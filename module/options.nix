{
  lib,
  option-types,
  nixrs,
  RUST-EDITIONS,
  CRATE-INFO,
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
    attrsOf
    listOf
    oneOf
    nullOr
    ;
  inherit (option-types)
    semantic-version
    dependency
    crate-output
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
      type = semantic-version;
    };
    edition = mkOption {
      description = "The Rust edition this crate uses.";
      type = enum RUST-EDITIONS;
    };
    features = mkOption {
      description = "Crate features (for conditional compilation).";
      type = attrsOf (listOf str);
      default = {
        default = [ ];
      };
    };

    meta = {
      authors = mkOption {
        description = "The crate's authors.";
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
        type = nullOr path;
        default = /${CRATE-INFO.root}/README.md;
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

    # Global dependencies - added for all outputs, unless overridden.
    dependencies = mkOption {
      description = "Any programs or libraries that this crate needs to run.";
      type = attrsOf dependency;
      default = { };
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
      type = attrsOf crate-output;
      default = { };
    };

    # Local settings that only affect your developer environment. None of these
    # settings are used if your crate is imported as a dependency.
    dev-env = {
      profiles = mkOption {
        description = "Profiles are similar to crate outputs, but allow you to specify more settings and are only available in your developer environment (i.e. other crates that add this crate as a dependency cannot use its profiles).";
        type = attrsOf (submodule {
          options = {
            output = mkOption {
              description = "The crate output to compile. You may specify the name of an output in the `outputs` table or just define a new output right here.";
              type = oneOf [
                str
                crate-output
              ];
            };
            inherit (nixrs.rustc-args) codegen;
          };
        });
      };

      toolchain = {
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
