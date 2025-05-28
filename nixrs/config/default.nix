{
  pkgs,
  dependencyConfigToList,
  dependenciesToSettings,
  compile,
  currentSystemRust,
  installToolchain,
  ...
}:

config: cratePath:

let
  crateStorePath = pkgs.lib.fileset.toSource {
    root = cratePath;
    fileset = cratePath;
  };
  toolchain = installToolchain {
    inherit (config.toolchain)
      channel
      date
      profile
      components
      ;
    customTargetComponents = config.toolchain.custom-target-components;
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
}
