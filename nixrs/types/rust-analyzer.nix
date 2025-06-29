{
  nixty,
  VALID_RUST_EDITIONS_STR,
  toJSON,
  ...
}:

with nixty.prelude;
rec {
  serialise = val: toJSON (nixty.strip val);
  project-json = newType {
    name = "ra-project-json";
    def = {
      sysroot = nullOr str;
      sysroot_src = nullOr str;
      cfg_groups = nullOr (setOf (listOf str));
      crates = listOf crate;
    };
  };
  crate = newType {
    name = "ra-crate";
    def = {
      display_name = str;
      root_module = str;
      edition = oneOfVal VALID_RUST_EDITIONS_STR;
      version = str;
      deps = listOf dep;
      is_workspace_member = bool;
      source = nullOr (newType {
        name = "ra-crate-source";
        def = {
          include_dirs = listOf str;
          exclude_dirs = listOf str;
        };
      });
      cfg_groups = nullOr (listOf str);
      cfg = listOf str;
      target = nullOr str;
      env = setOf str;
      is_proc_macro = bool;
      proc_macro_dylib_path = nullOr str;
      repository = nullOr str;
      build = nullOr build-info;
    };
  };
  dep = newType {
    name = "ra-dep";
    def = {
      crate = int;
      name = str;
    };
  };
  build-info = newType {
    name = "ra-build-info";
    def = {
      label = str;
      build_file = str;
      target_kind = oneOfVal [
        "bin"
        "lib"
        "test"
      ];
    };
  };
  runnable = newType {
    name = "ra-runnable";
    program = str;
    args = listOf str;
    cwd = str;
    kind = str;
  };
}
