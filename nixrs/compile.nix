# Wraps around rustc to provide a simple API to Nix for compiling a single Rust
# crate.

{
  concatStringsSep,
  map,
  filter,
  pkgs,
  toJSON,
  ...
}:

{
  crateName, # str: name of crate to compile
  crateType, # str<one of rustc crate types>: Type of crate to compile
  sysroot, # path: path to the sysroot of the Rust toolchain to compile with
  linkerPath, # path: path to the linker to use
  edition, # int<one of valid Rust editions>: Rust edition to compile with
  target, # str: target triple to compile for
  src, # path: nix store path to the crate's main file (e.g. main.rs, lib.rs)
  cfg, # [compilationSetting]: extra compilation settings to pass to rustc
  preventToolchainGc, # bool: add a symlink to the toolchain so it isn't gc'd
  raCrates ? null, # null or [rustAnalyzerCrate]: if !null, used to make RA cfg
}:

let
  rustcBaseArgs = [
    src
    "--crate-name"
    crateName
    "--crate-type"
    crateType
    "--edition"
    (toString edition)
    "-C"
    "linker=${linkerPath}"
    "--out-dir"
    "$out"
    "--sysroot"
    sysroot
    "--target"
    target
  ];

  links = map (cfg: "-L${toString cfg.path}") (filter (cfg: cfg.kind == "link") cfg);

  rustcArgs = rustcBaseArgs ++ links;

  foreignDeps = map (cfg: "${cfg.name}=${toString cfg.path}") (
    filter (cfg: cfg.kind == "foreign") cfg
  );
  basePath = [
    "${sysroot}/bin"
    "${pkgs.coreutils}/bin"
  ];
  additionalPath = map (cfg: cfg.path) (filter (cfg: cfg.kind == "path") cfg);
  path = basePath ++ additionalPath;

  raCfg =
    if raCrates == null then
      null
    else
      toJSON {
        inherit sysroot;
        crates = raCrates;
      };

  genIf = flag: string: if flag then string else "";
in
derivation {
  name = crateName;
  # TODO: Some crates may only support some systems, should maybe set that here
  system = builtins.currentSystem;
  builder = "${pkgs.bash}/bin/bash";
  outputs = [ "out" ];
  args = [
    "-c"
    ''
      rustc ${concatStringsSep " " rustcArgs}
      ${genIf preventToolchainGc "ln -s ${sysroot} $out/toolchain-sysroot"}
      ${genIf (raCfg != null) "echo '${raCfg}' > $out/rust-project.json"}
    ''
  ];

  # Environment variables
  PATH = concatStringsSep ":" path;
  NIXRS_FOREIGN_DEPENDENCIES = concatStringsSep ":" foreignDeps;
}
