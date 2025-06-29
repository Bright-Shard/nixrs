{
  pkgs,
  rustc,
  toolchain,
  config,
  toPath,
  elem,
  dependenciesToCompilationSettings,
  CRATE-ROOT,
  CURRENT-SYSTEM-RUST,
  IS-WORKSPACE-ROOT,
  ...
}:

let
  srcRoot =
    if
      elem config.crate-type [
        "lib"
        "proc-macro"
      ]
    then
      "src/lib.rs"
    else if config.crate-type == "bin" then
      "src/main.rs"
    else
      abort "unreachable";
in

rustc {
  crateName = config.name;
  crateType = config.crate-type;
  sysroot = toolchain.${CURRENT-SYSTEM-RUST}.SYSROOT;
  linkerPath = "${pkgs.gcc}/bin/cc"; # TODO allow custom linkers
  edition = config.edition;
  target = CURRENT-SYSTEM-RUST; # TODO allow overriding
  src = toPath "${CRATE-ROOT}/${srcRoot}";
  cfg = dependenciesToCompilationSettings config.dependencies;
  preventToolchainGc = config.workspace.toolchain.prevent-gc;
  genRaCfg = config.workspace.rust-analyzer.enable && IS-WORKSPACE-ROOT;
}
