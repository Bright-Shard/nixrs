# A crate to be downloaded by the `fetchCrate` function.

{ mkType, types, ... }:

mkType {
  typeName = "remoteCrate";
  schema = {
    # The name of the crate.
    name = "string";
    # The registry to download the crate from.
    registry = "string";
    # The version of the crate to download.
    version = types.crateVersion.isType;
  };
}
