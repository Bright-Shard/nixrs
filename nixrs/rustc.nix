# Wraps around rustc to provide a simple API to Nix for compiling a single Rust
# crate.

{
  concatStringsSep,
  map,
  filter,
  pkgs,
  toJSON,
  addErrorContext,
  replaceStrings,
  VALID_RUST_EDITIONS,
  nixty,
  types,
  ...
}:

let
  argsTy =
    with nixty.prelude;
    newType {
      name = "rustc-args";
      def = {
        # Name of the crate t ocompile
        crateName = str;
        # Type of crate to compile
        crateType = oneOfVal [
          "bin"
          "lib"
          "rlib"
          "dylib"
          "cdylib"
          "staticlib"
          "proc-macro"
        ];
        # Path to the current toolchain's sysroot
        sysroot = path;
        # Path to the linker to use
        linkerPath = path;
        # Rust edition to build with
        edition = oneOfVal VALID_RUST_EDITIONS;
        # target triple to compile for
        target = str;
        # Path to the crate's main file (e.g. main.rs or lib.rs)
        src = path;
        # Extra compilation settings to pass to rustc; see compilationSetting
        cfg = listOf types.compilationSetting;
        # Add a symlink to the toolchain sysroot so it doesn't get gc'd
        preventToolchainGc = bool;
        # If not null, crates to add to the rust-analyzer config
        raCrates = nullOr (listOf types.rustAnalyzerCrate);
      };
    };
in

rawArgs:

let
  args = argsTy rawArgs;
  rustcBaseArgs = [
    args.src
    "--crate-name"
    (replaceStrings [ "-" ] [ "_" ] args.crateName)
    "--crate-type"
    args.crateType
    "--edition"
    (toString args.edition)
    "-C"
    "linker=${args.linkerPath}"
    "--out-dir"
    "$out"
    "--sysroot"
    args.sysroot
    "--target"
    args.target
  ];

  links = map (cfg: "-L ${toString cfg.path}") (
    filter (cfg: cfg.kind == "link" || cfg.kind == "crate") args.cfg
  );
  crates = map (cfg: "--extern ${cfg.name}") (filter (cfg: cfg.kind == "crate") args.cfg);

  rustcArgs = rustcBaseArgs ++ links ++ crates;

  foreignDeps = map (cfg: "${cfg.name}=${toString cfg.path}") (
    filter (cfg: cfg.kind == "foreign") args.cfg
  );
  basePath = [
    "${args.sysroot}/bin"
    "${pkgs.coreutils}/bin"
  ];
  additionalPath = map (cfg: cfg.path) (filter (cfg: cfg.kind == "path") args.cfg);
  path = basePath ++ additionalPath;

  raCfg =
    if args.raCrates == null then
      null
    else
      toJSON {
        inherit (args) sysroot;
        crates = args.raCrates;
      };

  genIf = flag: string: if flag then string else "";
in
addErrorContext "While compiling ${args.crateName}" (derivation {
  name = args.crateName;
  # TODO: Some crates may only support some systems, should maybe set that here
  system = builtins.currentSystem;
  builder = "${pkgs.bash}/bin/bash";
  outputs = [ "out" ];
  args = [
    "-c"
    ''
      mkdir $out
      rustc ${concatStringsSep " " rustcArgs}
      ${genIf args.preventToolchainGc "ln -s ${args.sysroot} $out/toolchain-sysroot"}
      ${genIf (raCfg != null) "echo '${raCfg}' > $out/rust-project.json"}
    ''
  ];

  # Environment variables
  PATH = concatStringsSep ":" path;
  NIXRS_FOREIGN_DEPENDENCIES = concatStringsSep ":" foreignDeps;
})
