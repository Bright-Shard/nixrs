{ lib, nixrs }:

let
  inherit (builtins) match;
  inherit (lib) mkOption mkOptionType;
in
rec {
  inherit (lib.types)
    nullOr
    pathInStore
    listOf
    str
    bool
    oneOf
    submodule
    enum
    path
    attrsOf
    ;

  semanticVersion = mkOptionType {
    name = "Semantic Version";
    description = "A semantic version - see https://semver.org/.";
    check = val: match "^(0|[1-9][0-9]*|\\*)\\.?(0|[1-9][0-9]*|\\*)?\\.?(0|[1-9][0-9]*|\\*)?$" val;
  };
  crateVersion = mkOptionType {
    name = "Crate Version";
    description = "A crate version requirement - see https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html#version-requirement-syntax";
    # TODO this will panic instead of failing the check
    check = val: nixrs.types.crateVersion.fromString val;
  };

  baseDependencyConfig = {
    version = mkOption {
      description = "The dependency's version.";
      type = crateVersion;
    };
    source = mkOption {
      description = "The dependency's source.";
      type = nullOr pathInStore;
      default = null;
    };
    features = mkOption {
      description = "Features to enable for the dependency. Only supported for crate dependencies.";
      type = listOf str;
      default = [ "default" ];
    };
    optional = mkOption {
      description = "If this dependency is optional (i.e. is not required to build the crate).";
      type = bool;
      default = false;
    };
  };

  dependencyConfig = submodule {
    options = baseDependencyConfig // {
      kind = mkOption {
        description = ''
          The kind of dependency:
          - A **link** dependency, which is an external library that gets linked to the current crate
          - A **crate** dependency, which is an external Rust crate the current crate can use
        '';
        type = oneOf [
          "crate"
          "link"
        ];
        default = "crate";
      };
    };
  };
  buildDependencyConfig = submodule {
    options = baseDependencyConfig // {
      kind = mkOption {
        description = ''
          The kind of dependency:
          - A **binary** dependency, which is added to PATH for build scripts
          - A **foreign** dependency, which isn't handled by nixrs but is made available to build scripts
          - A **link** dependency, which is an external library that gets linked to the crate's build scripts
          - A **crate** dependency, which is an external Rust crate the build scripts can use
        '';
        type = oneOf [
          "binary"
          "crate"
          "link"
          "foreign"
        ];
        default = "crate";
      };
    };
  };
}
