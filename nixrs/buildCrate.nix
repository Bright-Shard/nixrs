# Wraps around rustc to provide a simple API to Nix for compiling Rust crates.

with builtins;

# Args:
# - crateName: str #name of crate to compile
# - crateType: str<one valid rustc crate type> #type of crate to compile
# - rustcPath: path #path to rustc
# - linkerPath: path #path to cc
# - edition: int<one valid rust edition> #rust edition to compile with
# - deps: [path] #paths to any dependency crates or C libraries
# - target: str #target triple to compile for
# - src: path #nix store path to the crate's source code
args:

derivation {
  name = args.crateName;
  # TODO: Some crates may only support some systems, would need to set that here
  system = builtins.currentSystem;
  builder = ./rustcWrapped.sh;
  outputs = [ "out" ];
  args =
    [
      "--crate-name"
      args.crateName
      "--crate-type"
      args.crateType
      "--edition"
      args.edition
      "-C"
      "linker=${args.linkerPath}"
      "${args.src}/src/main.rs" # TODO this won't always be main.rs
    ]
    ++ (concatLists (
      map (dep: [
        "-L"
        dep
      ]) args.deps
    ));
  RUSTC = args.rustcPath;
}
