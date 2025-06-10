{
  pkgs,
  dependenciesToCompilationSettings,
  rustc,
  currentSystemRust,
  toolchain,
  workspaceRoot,
  config,
  types,
  toString,
  toPath,
  elem,
  ...
}:

let
  crateStorePath = pkgs.lib.fileset.toSource {
    root = workspaceRoot;
    fileset = /${workspaceRoot}/src;
  };
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
  # TODO respect workspace setting for enabling this
  raCrate = types.rustAnalyzerCrate.build {
    root_module = srcRoot;
    edition = toString config.edition;
    deps = [ ]; # TODO
    is_workspace_member = true;
    cfg = [ ]; # TODO allow configuring
    env = { }; # TODO allow configuring
    is_proc_macro = false; # TODO
  };
in

rustc {
  crateName = config.name;
  crateType = config.crate-type;
  sysroot = toolchain.${currentSystemRust}.SYSROOT;
  linkerPath = "${pkgs.gcc}/bin/cc"; # TODO allow custom linkers
  edition = config.edition;
  target = currentSystemRust; # TODO allow overriding
  src = toPath "${crateStorePath}/${srcRoot}";
  cfg = dependenciesToCompilationSettings config.dependencies;
  preventToolchainGc = config.workspace.toolchain.prevent-gc;
  raCrates = [ raCrate ]; # TODO dependencies
}
