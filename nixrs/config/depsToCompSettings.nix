{
  typeOf,
  map,
  attrNames,
  types,
  compileCrate,
  fetchCrate,
  elem,
  config,
  toString,
  replaceStrings,
  ...
}:

let
  inherit (types) compilationSetting remoteCrate crateVersion;
  fetchAndCompileCrate =
    crate:
    compileCrate {
      crateRoot = fetchCrate (remoteCrate.build crate);
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
        else if
          elem dep.kind [
            "binary"
            "crate"
          ]
        then
          let
            path =
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
            kind =
              if dep.kind == "crate" then
                "crate"
              else if dep.kind == "binary" then
                "path"
              else
                abort "Unreachable";
          in
          {
            inherit kind;
            path = toString path;
          }
        else
          abort "Unreachable"
      else
        abort "Unreachable";
  in
  compilationSetting.build {
    name = depName;
    kind = kindAndPath.kind;
    path = kindAndPath.path;
  }

) (attrNames deps)
