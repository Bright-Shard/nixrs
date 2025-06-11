# An extra setting nixrs will pass to rustc.

{ nixty, ... }:

with nixty.prelude;

newType {
  name = "compilationSetting";
  def = {
    # The kind of compilation setting:
    # - Path settings add a path to the PATH variable for build scripts.
    # - Link settings add a library for rustc to link against.
    # - Foreign settings add an entry to the NIXRS_FOREIGN_DEPENDENCIES
    #   environment variable.
    kind = oneOfVal [
      "path"
      "crate"
      "link"
      "foreign"
    ];
    # The path to add to PATH, or the path to the library to link against, or
    # the path to add to NIXRS_FOREIGN_DEPENDENCIES, depending on the setting
    # type.
    path = oneOfTy [
      str
      path
    ];
    # Only used in foreign compilation settings. Sets the name that's used in
    # NIXRS_FOREIGN_DEPENDENCIES.
    name = str;
  };
}
