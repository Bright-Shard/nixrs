{
  typeOf,
  map,
  attrNames,
  types,
  ...
}:

deps:

assert typeOf deps == "set";

map (
  depName:
  let
    dep = deps.${depName};
  in
  if typeOf dep == "string" then
    types.dependency.registry.build {
      registry = "cratesio";
      name = depName;
      version = types.crateVersion.fromString dep;
    }
  else if typeOf dep == "set" then
    if dep.kind == "link" then
      types.dependency.store.build {
        path = dep.source;
        kind = "link";
      }
    else
      abort "TODO parse full dependency config"
  else
    abort "unreachable: dependency wasn't a string nor a set"
) (attrNames deps)
