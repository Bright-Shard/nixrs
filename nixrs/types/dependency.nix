# A dependency for a crate.

{
  mkType,
  elem,
  types,
  ...
}:

let
  inherit (types) crateVersion;
in

mkType {
  typeName = "dependency";
  schema = {
    # Dependencies must be created with `dependency.registry`,
    # `dependency.store`, or `dependency.foreign`. Example:
    #
    # ```nix
    # myDep = nixrs.types.dependency.registry.build {
    #   registry = "cratesio";
    #   name = "serde";
    #   version = nixrs.types.crateVersion.fromString "1";
    # };
    # ```
    dependency = val: abort "Cannot create dependency type directly.";
  };
  addFields = self: {
    # A dependency that needs to be downloaded from an online registry.
    registry = mkType {
      typeName = "dependency.registry";
      schema = {
        # Which registry the dependency needs to be downloaded from. This value
        # must match one of the registries in the `registries` table that gets
        # passed to nixrs when nixrs is loaded. For crates.io, the registry is
        # "cratesio".
        registry = "string";
        # The name of the crate that needs to be downloaded.
        name = "string";
        # The version of the crate that needs to be downloaded. You can get this
        # with `crateVersion.fromString` on a normal Cargo version requirement.
        version = crateVersion.isType;
      };
    };
    # A local dependency that exists in the Nix store.
    store = mkType {
      typeName = "dependency.store";
      schema = {
        # The path to the dependency in the Nix store.
        path = "path";
        # Tells nixrs how to handle this dependency:
        # - Binary dependencies are put in the PATH of build scripts.
        # - Crate dependencies are compiled and linked to the current crate.
        # - Link dependencies are static/dynamic libraries that get linked to
        #   the current crate.
        kind =
          kind:
          elem kind [
            "binary"
            "crate"
            "link"
          ];
      };
    };
    # A local dependency in the Nix store that is made available to build
    # scripts and isn't handled by nixrs.
    #
    # Foreign dependencies are passed to build scripts via the
    # `NIXRS_FOREIGN_DEPENDENCIES` environment variable. The environment
    # variable's format is similar to that of the PATH environment variable,
    # and looks like this:
    #
    # `NAME=/absolute/path/to/dependency:NAME2=/absolute/path/to/dependency`
    #
    # Where the name and path values are the exact values set in this table.
    foreign = mkType {
      typeName = "dependency.foreign";
      schema = {
        # The Nix store path to the dependency.
        path = "path";
        # The name of the dependency.
        name = "string";
      };
    };
    # monkeypatch isType
    isType =
      val:
      val.type == "dependency.registry"
      || val.type == "dependency.store"
      || val.type == "dependency.foreign";
  };
}
