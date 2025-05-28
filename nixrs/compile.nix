# Wraps around rustc to provide a simple API to Nix for compiling a single Rust
# crate.

{
  concatStringsSep,
  map,
  filter,
  placeholder,
  ...
}:

# Args:
# - crateName: str #name of crate to compile
# - crateType: str<one valid rustc crate type> #type of crate to compile
# - rustcPath: path #path to rustc
# - linkerPath: path #path to cc
# - edition: int<one valid rust edition> #rust edition to compile with
# - target: str #target triple to compile for, in rustc format
# - src: path #nix store path to the crate's main source file (eg main.rs)
# - cfg: [compilationSetting] #extra compilation settings to pass to rustc
args:

let
  rustcBaseArgs = [
    args.src
    "--crate-name"
    args.crateName
    "--crate-type"
    args.crateType
    "--edition"
    (toString args.edition)
    "-C"
    "linker=${args.linkerPath}"
    "--out-dir"
    (placeholder "out")
  ];

  links = map (cfg: "-L${toString cfg.path}") (filter (cfg: cfg.kind == "link") args.cfg);

  rustcArgs = rustcBaseArgs ++ links;

  foreignDeps = map (cfg: "${cfg.name}=${toString cfg.path}") (
    filter (cfg: cfg.kind == "foreign") args.cfg
  );
in
derivation {
  name = args.crateName;
  # TODO: Some crates may only support some systems, should maybe set that here
  system = builtins.currentSystem;
  builder = args.rustcPath;
  outputs = [ "out" ];
  args = rustcArgs;

  # Environment variables
  PATH = concatStringsSep ":" (map (cfg: cfg.path) (filter (cfg: cfg.kind == "path") args.cfg));
  NIXRS_FOREIGN_DEPENDENCIES = concatStringsSep ":" foreignDeps;
}
