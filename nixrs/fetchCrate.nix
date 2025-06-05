# Downloads a crate from an online crate registry so nixrs can compile it.

{
  registries,
  types,
  stringLength,
  substring,
  hasAttr,
  addErrorContext,
  readFile,
  split,
  map,
  filter,
  typeOf,
  fromJSON,
  ...
}:

let
  inherit (types) remoteCrate;
in

crate:
addErrorContext "While downloading the crate `${crate.name}`" (
  assert remoteCrate.isType crate;
  if !(hasAttr crate.registry registries) then
    abort "Crate needs to be downloaded from the registry `${crate.registry}`, but no index for this registry was passed to nixrs"
  else
    let
      registry = registries.${crate.registry};
      # TODO: Nix string operations run off of bytes, so this will break for any
      # multi-byte UTF-8 characters (i.e. stringLength returns the number of
      # bytes, not the number of characters). Nix doesn't have any built-in
      # functions for working with UTF-8, nor does it seem to have a way to work
      # with the bytes of a string, so I'll need to find some other solution for
      # working with UTF-8 in the future.
      #
      # This issue is fine for crates.io because crates.io only allows ASCII
      # crate names.
      nameLen = stringLength crate.name;
      path =
        if nameLen == 1 then
          /${registry}/1/${crate.name}
        else if nameLen == 2 then
          /${registry}/2/${crate.name}
        else if nameLen == 3 then
          /${registry}/3/${substring 0 1 crate.name}/${crate.name}
        else
          /${registry}/${substring 0 2 crate.name}/${substring 2 2 crate.name}/${crate.name};
      crateInfoLines = split "\n" (readFile path);
      crateInfo = map (val: fromJSON val) (
        filter (val: typeOf val == "string" && val != "") crateInfoLines
      );
    in
    abort "Crate meta: ${toString (map (info: builtins.toJSON info) crateInfo)}"
)
