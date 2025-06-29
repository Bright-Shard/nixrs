# Custom option types in nixrs' module.

{
  lib,
  types,
  ...
}:

let
  inherit (lib) mkOption;
  inherit (lib.types)
    nullOr
    listOf
    str
    bool
    oneOf
    enum
    path
    strMatching
    submodule
    ;
in

rec {
  semantic-version = strMatching types.semantic-version.regex;
  dependency-version = strMatching types.dependency-version.regex;

  dependency-config = submodule {
    options = {
      version = mkOption {
        description = "The dependency's version. Only necessary for crates downloaded from an online repository.";
        type = nullOr dependency-version;
      };
      crate-repo = mkOption {
        description = "The crate repository to download this crate from. Note that this is a crate repository (like crates.io), not a Git repository.";
        type = str;
        default = "cratesio";
      };
      source = mkOption {
        description = "The path to the dependency's root folder (i.e. the parent folder of the library for link dependencies, the parent folder of `crate.nix` for crate dependencies).";
        type = nullOr path;
        default = null;
      };
      features = mkOption {
        description = "Features to enable for the dependency. Only supported for crate dependencies.";
        type = listOf str;
        default = [ "default" ];
      };
      optional = mkOption {
        description = "If this dependency is optional (i.e. is not required to build the crate). You can make the dependency required via feature flags.";
        type = bool;
        default = false;
      };
      kind = mkOption {
        description = ''
          The kind of dependency:
          - A **binary** dependency, which is added to PATH for build scripts
          - A **foreign** dependency, which isn't handled by nixrs but is made available to build scripts and other compile-time code
          - A **link** dependency, which is an external library that gets linked to the crate's build scripts
          - A **crate** dependency, which is an external Rust crate the build scripts can use
        '';
        type = enum [
          "binary"
          "crate"
          "link"
          "foreign"
        ];
        default = "crate";
      };
    };
  };
  dependency = oneOf [
    path
    dependency-version
    dependency-config
  ];
}
