{
  types,
  fetch-crate,
  parse-crate,
  fallback,
  foldl',
  attrNames,
  mapAttrs,
  toPath,
  readDir,
  typeOf,
  ...
}:

# TODO type-check `module`
module:

let
  inherit (types) crate dependency-version;
  inherit (module.CRATE-INFO) config crate-root;

  root-folder = readDir crate-root;
  src-folder =
    if root-folder ? src && root-folder.src == "directory" then readDir "${crate-root}/src" else null;

  is-lib = src-folder ? "lib.rs";
  is-bin = src-folder ? "main.rs";
  has-prebuild = root-folder ? "prebuild.rs";
  has-postbuild = root-folder ? "postbuild.rs";

  lib-output = if is-lib then "lib" else null;
  bin-output = if is-bin then "bin" else null;
  prebuild-output = if has-prebuild then "prebuild" else null;
  postbuild-output = if has-postbuild then "postbuild" else null;

  parse-deps =
    config-deps:
    foldl'
      (
        acc: dep-name:
        let
          dep = config-deps.${dep-name};
        in

        if typeOf dep == "string" then
          fetch-crate {
            name = dep-name;
            version = dependency-version.from-string dep;
            repo = "cratesio";
          }
        else if typeOf dep == "path" then
          let
            crate = parse-crate dep;
          in
          {
            inherit (acc) link-dependencies search-paths;
            crate-dependencies = acc.crate-dependencies ++ [
              {
                inherit crate;
                output = crate.default-outputs.lib;
                version = null;
                enabled-features = [ "default" ];
              }
            ];
          }
        else if dep.optional then
          acc
        else if dep.kind == "binary" then
          abort "TODO"
        else if dep.kind == "crate" then
          let
            crate =
              if dep.source != null then
                parse-crate dep.source
              else
                fetch-crate {
                  name = dep-name;
                  version = dep.version;
                  repo = dep.crate-repo;
                };
          in
          {
            inherit (acc) link-dependencies search-paths;
            crate-dependencies = acc.crate-dependencies ++ [
              {
                inherit crate;
                # TODO allow configuring
                output = crate.default-outputs.lib;
                version = if dep.version != null then dependency-version.from-string dep.version else null;
                # TODO allow configuring
                # TODO support features in rustc.nix
                enabled-features = [ "default" ];
              }
            ];
          }
        else if dep.kind == "link" then
          {
            inherit (acc) crate-dependencies;
            # TODO allow specifying library kind
            link-dependencies = acc.link-dependencies ++ [ { name = dep-name; } ];
            search-paths = acc.search-paths ++ [
              {
                # TODO set to framework for framework link deps
                kind = "native";
                path = dep.source;
              }
            ];
          }
        else if dep.kind == "foreign" then
          abort "TODO"
        else
          abort "unreachable"
      )
      {
        crate-dependencies = [ ];
        link-dependencies = [ ];
        search-paths = [ ];
      }
      (attrNames config-deps);

  package-deps = parse-deps config.dependencies;
  parsed-outputs = mapAttrs (
    output-name: output:
    let
      output-deps = parse-deps output.dependencies;
    in
    {
      # TODO: Give a proper error message for outputs missing config fields
      inherit (output) source;
      # TODO: will need to let the output override package dependencies
      crate-dependencies = package-deps.crate-dependencies ++ output-deps.crate-dependencies;
      link-dependencies = package-deps.link-dependencies ++ output-deps.link-dependencies;
      search-paths = package-deps.search-paths ++ output-deps.search-paths;
      edition = fallback output.edition config.edition;
      crate-type = output.crate-type;
      default-target = fallback output.target-triple config.compilation.target-triple;
    }
  ) config.outputs;
in
crate {
  meta = {
    inherit (config) name features;
    version = types.semantic-version.from-string config.version;
  };
  workspace-info = {
    member = false; # TODO
    toolchain = null; # TODO
  };
  outputs =
    let
      shared-opts = {
        inherit (package-deps) crate-dependencies link-dependencies search-paths;
        edition = config.edition;
        default-target = config.compilation.target-triple;
      };
    in
    parsed-outputs
    // {
      ${lib-output} =
        (
          shared-opts
          // {
            source = toPath "${crate-root}/src/lib.rs";
            crate-type = "lib";
          }
        )
        // (parsed-outputs.lib or { });
      ${bin-output} =
        (
          shared-opts
          // {
            source = toPath "${crate-root}/src/main.rs";
            crate-type = "bin";
          }
        )
        // (parsed-outputs.bin or { });
      ${prebuild-output} =
        (
          shared-opts
          // {
            source = toPath "${crate-root}/prebuild.rs";
            crate-type = "bin";
          }
        )
        // (parsed-outputs.prebuild or { });
      ${postbuild-output} =
        (
          shared-opts
          // {
            source = toPath "${crate-root}/postbuild.rs";
            crate-type = "bin";
          }
        )
        // (parsed-outputs.postbuild or { });
    };
  default-outputs = {
    lib = lib-output;
    bin = bin-output;
    prebuild = prebuild-output;
    postbuild = postbuild-output;
  };
}
