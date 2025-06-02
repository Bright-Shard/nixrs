{
  pkgs,
  dependencyConfigToList,
  dependenciesToSettings,
  compile,
  currentSystemRust,
  toolchain,
  workspaceRoot,
  config,
  types,
  toString,
  ...
}:

let
  crateStorePath = pkgs.lib.fileset.toSource {
    root = workspaceRoot;
    fileset = workspaceRoot;
  };
  raCrate = types.rustAnalyzerCrate.build {
    root_module = "src/main.rs"; # TODO
    edition = toString config.edition;
    deps = [ ];
    is_workspace_member = true;
    cfg = [ ];
    env = { };
    is_proc_macro = false; # TODO
  };
in

# TODO build scripts
compile {
  crateName = config.name;
  crateType = "bin"; # TODO support multiple crate types
  sysroot = toolchain.${currentSystemRust}.SYSROOT;
  linkerPath = "${pkgs.gcc}/bin/cc"; # TODO allow custom linkers
  edition = config.edition;
  target = currentSystemRust; # TODO allow overriding
  src = "${crateStorePath}/src/main.rs"; # TODO
  cfg = dependenciesToSettings (dependencyConfigToList config.dependencies);
  preventToolchainGc = config.toolchain.prevent-gc;
  raCrates = [ raCrate ]; # TODO dependencies
}
