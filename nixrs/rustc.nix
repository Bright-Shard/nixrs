# Wraps around rustc to provide an explicit API to Nix for compiling a single
# Rust crate. Returns a derivation to a folder with all compilation outputs
# inside.

{
  concatStringsSep,
  concatLists,
  map,
  mapAttrs,
  attrNames,
  currentSystem,
  addErrorContext,
  typeOf,
  toJSON,
  pkgs,
  types,
  nixty,
  ...
}:

raw-args:

let
  args = types.rustc-args.args raw-args;
  nullable-flag =
    arg: flag:
    if arg != null then
      [
        flag
        arg
      ]
    else
      [ ];
in
addErrorContext "While compiling ${args.crate-name}" (derivation {
  name = args.crate-name;
  # TODO: Some crates may only support some systems; should maybe allow
  # setting that here
  system = currentSystem;
  builder = "${args.sysroot}/${args.rustc}";
  outputs = [ "out" ];
  args =
    [
      args.root
      "--crate-name"
      args.crate-name
      "--edition"
      (toString args.edition)
      "--sysroot"
      args.sysroot
      "--out-dir"
      (placeholder "out")
    ]
    ++ [
      "--crate-type"
      (
        if typeOf args.crate-type == "string" then args.crate-type else concatStringsSep "," args.crate-type
      )
    ]
    ++ (
      let
        ty = typeOf args.emit;
      in
      if ty == "string" then
        [
          "--emit"
          args.emit
        ]
      else if ty == "list" then
        [
          "--emit"
          (concatStringsSep "," args.emit)
        ]
      else
        [ ]
    )
    ++ (nullable-flag args.target "--target")
    ++ (nullable-flag args.error-format "--error-format")
    ++ (if args.build-test-harness then [ "--test" ] else [ ])
    ++ concatLists (
      map (val: [
        "--extern"
        (
          if typeOf val == "string" then
            val
          else if val.path != null then
            "${val.name}=${val.path}"
          else
            "${val.name}"
        )
      ]) args.extern-crates
    )
    ++ concatLists (
      map (val: [
        "-L"
        (
          if typeOf val == "string" then
            val
          else if val.kind != null then
            "${val.kind}=${val.path}"
          else
            "${val.path}"
        )
      ]) args.search-paths
    )
    ++ concatLists (
      map (val: [
        "-l"
        (
          if typeOf val == "string" then
            val
          else
            let
              kind =
                if val.kind != null then
                  if val.modifiers != null then
                    "${val.kind}:${concatStringsSep "," val.modifiers}="
                  else
                    "${val.kind}="
                else
                  "";
            in
            if val.rename != null then "${kind}${val.name}:${val.rename}" else "${kind}${val.name}"
        )
      ]) args.native-libraries
    )

    # Codegen Options
    ++ concatLists (
      map (
        key:
        let
          val = args.codegen.${key};
        in
        if val == null then
          [ ]
        else if key == "unsafe-target-feature" then
          [
            "-C"
            "target-feature=\"${
              concatStringsSep "," (
                mapAttrs (feature: enabled: if enabled then "+${feature}" else "-${feature}") val
              )
            }\""
          ]
        else if typeOf val == "string" then
          [
            "-C"
            "${key}=${val}"
          ]
        else if typeOf val == "list" then
          [
            "-C"
            "${key}=\"${concatStringsSep " " val}\""
          ]
        else
          [
            "-C"
            "${key}=${toJSON val}"
          ]
      ) (attrNames (nixty.stripInstance args.codegen))
    )

    ++ args.custom-args;

  # Environment variables
  PATH = "${args.sysroot}/bin:${pkgs.coreutils}/bin";
})
