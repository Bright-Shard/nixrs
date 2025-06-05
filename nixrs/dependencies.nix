# Takes a list of `dependency` objects and returns a list of
# `compilationSetting` objects.

{
  types,
  fetchCrate,
  readDir,
  nixrs,
  ...
}:

dependencies:

let
  inherit (types) dependency compilationSetting;
  compileCrate =
    crate:
    let
      crateRoot = readDir crate.path;
    in
    if crateRoot ? "build.nix" then
      import "${crateRoot}/build.nix" nixrs
    else if crateRoot ? "crate.nix" then
      abort "TODO: nixrs crate"
    else if crateRoot ? "Cargo.toml" then
      abort "TODO: Cargo crate"
    else
      abort "Dependency at `${crate.path}` is supposed to be a crate, but it doesn't have a `Cargo.toml` file nor a `crate.nix` file.";
in
map (
  dep:
  assert dependency.isType dep;
  if dependency.registry.isType dep then
    compileCrate (fetchCrate dep)
  else if dependency.store.isType dep then
    if dep.kind == "binary" then
      compilationSetting.build {
        kind = "path";
        path = dep.path;
        name = "";
      }
    else if dep.kind == "link" then
      compilationSetting.build {
        kind = "link";
        path = dep.path;
        name = "";
      }
    else if dep.kind == "crate" then
      compileCrate dep
    else
      abort
  else if dependency.foreign.isType dep then
    compilationSetting.build {
      kind = "foreign";
      path = dep.path;
      name = dep.name;
    }
  else
    abort
) dependencies
