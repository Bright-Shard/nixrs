# Wraps around rustc to provide an explicit API to Nix for compiling a single
# Rust crate. Returns a derivation to a single file (the compiled crate).

{
  concatStringsSep,
  concatLists,
  map,
  currentSystem,
  addErrorContext,
  pkgs,
  nixty,
  VALID-RUST-EDITIONS,
  VALID-CRATE-TYPES,
  NATIVE-LIBRARY-TYPES,
  SEARCH-PATH-TYPES,
  ...
}:

let
  inherit (nixty) type;

  args-ty =
    with nixty.prelude;
    newType {
      name = "rustc-args";
      def = {
        # Path to crate's root (e.g. main.rs or lib.rs)
        root = str;
        # Name of crate to compile
        crate-name = str;
        # Rust edition to build with
        edition = oneOfVal VALID-RUST-EDITIONS;
        # Type of crate to compile (can specify one type or many types)
        crate-type = oneOfTy [
          (oneOfVal VALID-CRATE-TYPES)
          (listOf (oneOfVal VALID-CRATE-TYPES))
        ];
        # External crates this crate uses
        extern-crates = listOf (oneOfTy [
          str
          (newType {
            name = "rustc-args-extern-path";
            def = {
              name = str;
              path = nullOr (oneOfTy [
                path
                str
              ]);
            };
          })
        ]);
        # Paths to add to rustc's search paths
        search-paths = listOf (oneOfTy [
          str
          (newType {
            name = "rustc-args-search-path";
            def = {
              kind = nullOr (oneOfVal SEARCH-PATH-TYPES);
              path = str;
            };
          })
        ]);
        # Native libraries to link against
        native-libraries = listOf (oneOfTy [
          str
          (newType {
            name = "rustc-args-native-library";
            def = {
              kind = nullOr (oneOfVal NATIVE-LIBRARY-TYPES);
              modifiers = nullOr (
                listOf (oneOfVal [
                  "bundle"
                  "verbatim"
                  "whole-archive"
                  "as-needed"
                ])
              );
              name = str;
              rename = nullOr str;
            };
          })
        ]);
        # Output formats to emit
        emit =
          let
            accepted = oneOfVal [
              "asm"
              "dep-info"
              "link"
              "llvm-bc"
              "llvm-ir"
              "metadata"
              "mir"
              "obj"
            ];
          in
          nullOr (oneOfTy [
            (listOf accepted)
            accepted
          ]);
        # Error format printed by rustc
        error-format = nullOr (oneOfVal [
          "human"
          "json"
          "short"
        ]);
        # Target triple to compile for
        target = nullOr str;
        # Build a test harness instead of just the normal crate
        build-test-harness = bool;
        # Path to the current toolchain's sysroot
        sysroot = str;
        # Path to the linker to use
        linker = str;
        # Path to rustc, relative to the toolchain's sysroot
        rustc = withDefault "bin/rustc" str;
      };
    };
in

raw-args:

let
  args = args-ty raw-args;
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
      "-C"
      "linker=${args.linker}"
      "--out-dir"
      (placeholder "out")
    ]
    ++ [
      "--crate-type"
      (if type args.crate-type == "string" then args.crate-type else concatStringsSep "," args.crate-type)
    ]
    ++ (
      let
        ty = type args.emit;
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
          if type val == "string" then
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
          if type val == "string" then
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
          if type val == "string" then
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
    );

  # Environment variables
  PATH = "${args.sysroot}/bin:${pkgs.coreutils}/bin";
})
