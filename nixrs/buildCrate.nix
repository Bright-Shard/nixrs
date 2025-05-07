# Wraps around rustc to provide a simple API to Nix for compiling a single Rust
# crate.

with builtins;

# Args:
# - crateName: str #name of crate to compile
# - crateType: str<one valid rustc crate type> #type of crate to compile
# - rustcPath: path #path to rustc
# - bashPath: path #path to bash
# - linkerPath: path #path to cc
# - edition: int<one valid rust edition> #rust edition to compile with
# - links: [path] #paths to any dependency crates or C libraries to link with
# - target: str #target triple to compile for
# - src: path #nix store path to the crate's main source file (eg main.rs)
args:

let
  rustcBaseArgs = "${args.src} --crate-name ${args.crateName} --crate-type ${args.crateType} --edition ${toString args.edition} -C linker=${args.linkerPath} --out-dir $out";
  rustcArgs = concatStringsSep " -L " ([ rustcBaseArgs ] ++ args.links);
in
derivation {
  name = args.crateName;
  # TODO: Some crates may only support some systems, would need to set that here
  system = builtins.currentSystem;
  builder = args.bashPath;
  outputs = [ "out" ];
  args = [
    "-c"
    "${args.rustcPath} ${rustcArgs}"
  ];
}
