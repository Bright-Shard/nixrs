{
  lib,
  workspaceRoot,
  ...
}:

let
  inherit (lib) mkOption;
  inherit (lib.types)
    nullOr
    listOf
    str
    submodule
    path
    ;
in

mkOption {
  description = "Crate metadata.";
  default = { };
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
        default = /${workspaceRoot}/README.md;
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
}
