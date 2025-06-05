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
    submodule
    enum
    pathInStore
    strMatching
    ;
in

rec {
  semanticVersion = strMatching types.semanticVersion.regex;
  crateVersion = strMatching types.crateVersion.regex;

  dependencyConfig = submodule {
    options = {
      version = mkOption {
        description = "The dependency's version. Only necessary for crates downloaded from an online repository.";
        type = crateVersion;
      };
      repo = mkOption {
        description = "The crate repository to download this crate from.";
        type = str;
        default = "cratesio";
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
      kind = mkOption {
        description = ''
          The kind of dependency:
          - A **binary** dependency, which is added to PATH for build scripts
          - A **foreign** dependency, which isn't handled by nixrs but is made available to build scripts
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
    crateVersion
    dependencyConfig
  ];
}
