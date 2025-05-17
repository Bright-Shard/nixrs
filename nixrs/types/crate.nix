{ mkType, ... }:

mkType {
  typeName = "crate";
  schema = {
    name = "string"; # Name of crate
    version = "string"; # Version of crate
    edition = "int"; # Rust edition to compile with
  };
}
