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
  else
    abort ""
) (attrNames deps)
