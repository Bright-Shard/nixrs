{
  typeOf,
  map,
  attrNames,
  types,
  compileCrate,
  fetchCrate,
  elem,
  ...
}:

let
  inherit (types) compilationSetting remoteCrate crateVersion;
  fetchAndCompileCrate = crate: compileCrate (fetchCrate (remoteCrate.build crate));
in

deps:

map (
  depName:
  let
    dep = deps.${depName};
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
            abort "The ${dep.kind} dependency `${depName}` must have `source` set"
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
                dep.source
              else if dep.version != null then
                fetchAndCompileCrate {
                  name = depName;
                  registry = dep.repo;
                  version = dep.version;
                }
              else
                abort "Dependency `${depName}` must have `source` or `version` set";
            kind =
              if dep.kind == "crate" then
                "link"
              else if dep.kind == "binary" then
                "path"
              else
                abort "Unreachable";
          in
          {
            inherit path kind;
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
