{
  nixty,
  SEARCH-PATH-TYPES,
  RUST-EDITIONS,
  CRATE-TYPES,
  EMIT-OBJECT-TYPES,
  LINKER-FLAVORS,
  RELOCATION-MODELS,
  ...
}:

with nixty.prelude;
rec {
  # Type for search paths to add to rustc.
  search-path-full = newType {
    name = "nixrs-rustc-searchPath";
    def = {
      kind = nullOr (oneOfVal SEARCH-PATH-TYPES);
      path = str;
    };
  };
  search-path = oneOfTy [
    str
    search-path-full
  ];

  # Type for native libraries to tell rustc to link against.
  native-library-full = newType {
    name = "nixrs-rustc-nativeLibrary";
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
  };
  native-library = oneOfTy [
    str
    native-library-full
  ];

  # Type for dependency crates to tell rustc to link against.
  extern-crate-full = newType {
    name = "nixrs-rustc-externCrate";
    def = {
      name = str;
      path = nullOr (oneOfTy [
        path
        str
      ]);
    };
  };
  extern-crate = oneOfTy [
    str
    extern-crate-full
  ];

  # Codegen options - see
  # https://doc.rust-lang.org/rustc/codegen-options/index.html
  #
  # Unsupported options:
  # - link-args (pass an array to link-arg instead)
  #
  # Modified options:
  # - target-feature is renamed to unsafe-target-feature as the flag is
  #   documented to be unsafe.
  #
  # Flags that typically accept y/n/yes/no/true/false only accept booleans here.
  # Deprecated flags are not accepted here.
  codegen = newType {
    name = "nixrs-rustc-codegenOptions";
    def = {
      code-model = oneOfVal [
        null
        "tiny"
        "small"
        "kernel"
        "medium"
        "large"
      ];
      codegen-units = nullOr int;
      collapse-macro-debuginfo = oneOfTy [
        bool
        (oneOfVal [
          null
          "external"
        ])
      ];
      control-flow-guard = oneOfTy [
        bool
        (oneOfVal [
          null
          "checks"
          "nochecks"
        ])
      ];
      debug-assertions = nullOr bool;
      debuginfo = oneOfVal [
        null
        0
        1
        2
        "none"
        "limited"
        "full"
        "line-directives-only"
        "line-tables-only"
      ];
      default-linker-libraries = nullOr bool;
      dlltool = oneOfTy [
        primitives.null
        path
        str
      ];
      dwarf-version = oneOfVal [
        null
        2
        3
        4
        5
      ];
      embed-bitcode = nullOr bool;
      extra-filename = nullOr str;
      force-frame-pointers = nullOr bool;
      force-unwind-tables = nullOr bool;
      incremental = oneOfTy [
        primitives.null
        path
        str
      ];
      instrument-coverage = nullOr bool;
      link-arg = oneOfTy [
        primitives.null
        (listOf str)
        str
      ];
      link-dead-code = nullOr bool;
      link-self-contained = nullOr bool;
      linker = oneOfTy [
        str
        path
      ];
      linker-flavor = nullOr (oneOfVal LINKER-FLAVORS);
      linker-plugin-lto = oneOfTy [
        primitives.null
        bool
        path
        str
      ];
      llvm-args = nullOr (listOf str);
      lto = oneOfTy [
        bool
        (oneOfVal [
          null
          "thin"
          "fat"
        ])
      ];
      metadata = nullOr (listOf str);
      no-prepopulate-passes = nullOr bool;
      no-redzone = nullOr bool;
      no-vectorize-loops = nullOr bool;
      no-vectorize-slp = nullOr bool;
      opt-level = oneOfVal [
        null
        0
        1
        2
        3
        "s"
        "z"
      ];
      overflow-checks = nullOr bool;
      panic = oneOfVal [
        null
        "abort"
        "unwind"
      ];
      passes = nullOr (listOf str);
      prefer-dynamic = nullOr bool;
      profile-generate = oneOfTy [
        primitives.null
        path
        str
      ];
      profile-use = oneOfTy [
        primitives.null
        path
        str
      ];
      relocation-model = nullOr (oneOfVal RELOCATION-MODELS);
      relro-level = nullOr (oneOfVal [
        "off"
        "partial"
        "full"
      ]);
      remark = oneOfTy [
        primitives.null
        str
        (listOf str)
      ];
      rpath = nullOr bool;
      save-temps = nullOr bool;
      soft-float = nullOr bool;
      split-debuginfo = oneOfVal [
        null
        "off"
        "packed"
        "unpacked"
      ];
      strip = oneOfVal [
        null
        "debuginfo"
        "symbols"
      ];
      symbol-mangling-version = oneOfVal [
        null
        "v0"
      ];
      target-cpu = nullOr str;
      # Enable feature a, disable feature b:
      # unsafe-target-feature = {
      #   a = true;
      #   b = false;
      # };
      unsafe-target-feature = nullOr (setOf bool);
    };
  };

  args = newType {
    name = "nixrs-rustc-args";
    def = {
      # Path to crate's root (e.g. main.rs or lib.rs)
      root = str;
      # Name of crate to compile
      crate-name = str;
      # Rust edition to build with
      edition = oneOfVal RUST-EDITIONS;
      # Type of crate to compile (can specify one type or many types)
      crate-type = oneOfTy [
        (oneOfVal CRATE-TYPES)
        (listOf (oneOfVal CRATE-TYPES))
      ];
      # External crates this crate uses
      extern-crates = listOf extern-crate;
      # Paths to add to rustc's search paths
      search-paths = listOf search-path;
      # Native libraries to link against
      native-libraries = listOf native-library;
      # Output formats to emit
      emit = oneOfTy [
        primitives.null
        (listOf (oneOfVal EMIT-OBJECT-TYPES))
        (oneOfVal EMIT-OBJECT-TYPES)
      ];
      # Error format printed by rustc
      error-format = nullOr (oneOfVal [
        "human"
        "json"
        "short"
      ]);
      # Target triple to compile for
      target = nullOr str;
      # Build a test harness instead of just the normal crate
      build-test-harness = withDefault false bool;
      # Codegen options - see
      # https://doc.rust-lang.org/rustc/codegen-options/index.html
      inherit codegen;
      # Path to the current toolchain's sysroot
      sysroot = str;
      # Custom arguments to pass to rustc.
      custom-args = withDefault [ ] (listOf str);
      # Path to rustc, relative to the toolchain's sysroot
      rustc = withDefault "bin/rustc" str;
    };
  };
}
