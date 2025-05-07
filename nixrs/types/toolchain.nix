# A Rust toolchain to install.

with builtins;

import ./mkType {
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
