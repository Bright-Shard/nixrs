{
  pkgs,
  dependencySetToList,
  dependenciesToLinks,
  compile,
  ...
}:

config: cratePath:

let
  crateStorePath = pkgs.lib.fileset.toSource {
    root = cratePath;
    fileset = cratePath;
  };
in

# TODO build scripts
compile {
  crateName = config.name;
  crateType = "bin"; # TODO support multiple crate types
  rustcPath = config.compiler-options.rustc-path;
  bashPath = "${pkgs.bash}/bin/bash";
  linkerPath = "${pkgs.gcc}/bin/cc"; # TODO allow custom linkers
  edition = config.edition;
  links = dependenciesToLinks (dependencySetToList config.dependencies);
  target = "x86_64-unknown-linux-gnu"; # TODO use system target & allow override
  src = "${crateStorePath}/src/main.rs"; # TODO
}
