# Downloads a crate from an online crate registry so nixrs can compile it.
#
# Currently incomplete.

{
  registries,
  nixty,
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
  types,
  ...
}:

let
  args-ty =
    with nixty.prelude;
    newType {
      name = "fetch-crate-args";
      def = {
        # The name of the crate.
        name = str;
        # The version of the crate to download.
        version = types.dependency-version;
        # The registry to download the crate from.
        registry = withDefault "cratesio" str;
      };
    };
in

args-raw:
let
  args = args-ty args-raw;
in
addErrorContext "While downloading the crate `${args.name}`" (
  if !(hasAttr args.registry registries) then
    abort "Crate needs to be downloaded from the registry `${args.registry}`, but no index for this registry was passed to nixrs"
  else
    let
      registry = registries.${args.registry};
      # TODO: Nix string operations run off of bytes, so this will break for any
      # multi-byte UTF-8 characters (i.e. stringLength returns the number of
      # bytes, not the number of characters). Nix doesn't have any built-in
      # functions for working with UTF-8, nor does it seem to have a way to work
      # with the bytes of a string, so I'll need to find some other solution for
      # working with UTF-8 in the future.
      #
      # This issue is fine for crates.io because crates.io only allows ASCII
      # crate names.
      nameLen = stringLength args.name;
      path =
        if nameLen == 1 then
          /${registry}/1/${args.name}
        else if nameLen == 2 then
          /${registry}/2/${args.name}
        else if nameLen == 3 then
          /${registry}/3/${substring 0 1 args.name}/${args.name}
        else
          /${registry}/${substring 0 2 args.name}/${substring 2 2 args.name}/${args.name};
      allCrateVersions = map (val: fromJSON val) (
        filter (val: typeOf val == "string" && val != "") (split "\n" (readFile path))
      );
    in
    abort "Crate meta: ${toString (map (info: builtins.toJSON info) allCrateVersions)}"
)
