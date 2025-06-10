# An extra setting nixrs will pass to rustc.

{ mkType, elem, ... }:

mkType {
  typeName = "compilationSetting";
  schema = {
    # The kind of compilation setting:
    # - Path settings add a path to the PATH variable for build scripts.
    # - Link settings add a library for rustc to link against.
    # - Foreign settings add an entry to the NIXRS_FOREIGN_DEPENDENCIES
    #   environment variable.
    kind =
      val:
      elem val [
        "path"
        "crate"
        "link"
        "foreign"
      ];
    # The path to add to PATH, or the path to the library to link against, or
    # the path to add to NIXRS_FOREIGN_DEPENDENCIES, depending on the setting
    # type.
    path = [
      "string"
      "path"
    ];
    # Only used in foreign compilation settings. Sets the name that's used in
    # NIXRS_FOREIGN_DEPENDENCIES.
    name = "string";
  };
}
