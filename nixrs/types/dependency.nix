# A dependency for a crate.

with builtins;

import ./mkType {
  typeName = "dependency";
  schema = {
    # Where the dependency comes from - a local file, crates.io, GitHub, etc.
    source =
      source:
      elem source [
        "cratesio"
        "local"
        "git"
      ];
    # The path to the crate. The meaning of this is context-dependent:
    # - For local crates, this is the path to the crate's source code
    # - For crates.io crates, this is the URL where the crate can be downloaded
    # - For git crates, this is the URL to clone the git repo from
    path = "string";
    # Whether this dependency is another Rust crate or some other foreign
    # dependency. An example of a foreign dependency is a C library that a
    # Rust crate links to.
    kind =
      kind:
      elem kind [
        "crate"
        "foreign"
      ];
  };
}
