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
      customTargetComponents
      ;
  };
  rustcPath =
    if config.compiler.rustc-path != null then
      config.compiler.rustc-path
    else
      "${toolchain.${currentSystemRust}.SYSROOT}/bin/rustc";
in

# TODO build scripts
compile {
  crateName = config.name;
  crateType = "bin"; # TODO support multiple crate types
  inherit rustcPath;
  linkerPath = "${pkgs.gcc}/bin/cc"; # TODO allow custom linkers
  edition = config.edition;
  target = currentSystemRust; # TODO allow overriding
  src = "${crateStorePath}/src/main.rs"; # TODO
  cfg = dependenciesToSettings (dependencyConfigToList config.dependencies);
}
