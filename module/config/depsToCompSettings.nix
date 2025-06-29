{
  typeOf,
  map,
  attrNames,
  types,
  compileCrate,
  fetchCrate,
  elem,
  config,
  replaceStrings,
  ...
}:

let
  inherit (types) compilationSetting crateVersion;
  fetchAndCompileCrate =
    crate:
    compileCrate {
      crateRoot = fetchCrate crate;
      workspaceCfg = config.workspace;
    };
in

deps:

map (
  depNameRaw:
  let
    depName = replaceStrings [ "-" ] [ "_" ] depNameRaw;
    dep = deps.${depNameRaw};
    kindAndPath =
      if typeOf dep == "string" then
        {
          kind = "link";
          path = fetchAndCompileCrate {
            name = depName;
            registry = "cratesio";
            version = crateVersion.fromString dep;
          };
        }
      else if typeOf dep == "set" then
        if
          elem dep.kind [
            "foreign"
            "link"
          ]
        then
          if dep.source == null then
            abort "The ${dep.kind} dependency `${depNameRaw}` must have `source` set"
          else
            {
              kind = dep.kind;
              path = dep.source;
            }
        else
          let
            compiled =
              if dep.source != null then
                compileCrate {
                  crateRoot = dep.source;
                  workspaceCfg = config.workspace;
                }
              else if dep.version != null then
                fetchAndCompileCrate {
                  name = depName;
                  registry = dep.repo;
                  version = dep.version;
                }
              else
                abort "Dependency `${depNameRaw}` must have `source` or `version` set";
          in
          if dep.kind == "binary" then
            {
              kind = "path";
              path = compiled.drv;
            }
          else if dep.kind == "crate" then
            {
              kind = "crate";
              path = compiled.drv;
              crate = compiled;
            }
          else
            abort "Unreachable"
      else
        abort "Unreachable";
  in
  compilationSetting (
    kindAndPath
    // {
      name = depName;
    }
  )

) (attrNames deps)
