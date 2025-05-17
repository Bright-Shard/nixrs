# A Rust toolchain to install.

{ mkType, elem, ... }:

mkType {
  typeName = "toolchain";
  schema = {
    channel =
      channel:
      elem channel [
        "stable"
        "beta"
        "nightly"
      ];
    targets = "list";
    components = "list";
  };
}
