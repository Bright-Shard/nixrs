{
  pkgs,
  nixty,
  types,
  replaceStrings,
  rustc,
  fallback,
  currentSystem,
  RUST-EDITIONS,
  CRATE-TYPES,
  ...
}:

let
  crate-ty = nixty.newType {
    name = "crate";
    def = with nixty.prelude; {
      # General metadata.
      meta = {
        # Name of the crate as specified in the crate's manifest.
        #
        # This name may not be compatible with rustc; use `name-rustc` for that.
        name = str;
        # Version of the crate.
        version = types.semantic-version;
        # All available crate features. The keys are the feature names, the
        # values are the other features or dependencies it enables.
        features = setOf (listOf str);
      };
      # Information about the crate's relationship to the workspace we're
      # building.
      # TODO rename to dev env or something like that; nixrs doesn't really use
      # the term "workspace" anywhere else
      workspace-info = {
        # If this crate is a member of the workspace we're building.
        member = bool;
        # The toolchain to build this workspace with.
        toolchain = nullOr set;
      };
      # Outputs that can be built by nixrs.
      outputs = setOf (newType {
        name = "crate-output";
        def = {
          # The location of the output's main file.
          source = path;
          # The Rust edition to build this output with.
          edition = oneOfVal RUST-EDITIONS;
          # The type of crate to compile. Can specify one crate type or many.
          crate-type = oneOfTy [
            (oneOfVal CRATE-TYPES)
            (listOf (oneOfVal CRATE-TYPES))
          ];
          # Direct crate dependencies of the output. This is really just for
          # convenience since it works with the existing nixrs crate type
          # instead of having to build the crate yourself like with
          # `raw-crate-dependencies`.
          crate-dependencies = listOf types.dependency;
          # Less convenient version of `crate-dependencies`.
          raw-crate-dependencies = withDefault [ ] (listOf (types.rustc-args.extern-crate));
          # Search paths to find native libraries at.
          search-paths = listOf (types.rustc-args.search-path);
          # Native libraries to link against.
          native-libraries = listOf (types.rustc-args.native-library);
          # Codegen settings.
          codegen = nullOr types.rustc-args.codegen;
          # Target triple to compile for.
          target = nullOr str;
          # If this output is a private output. Private outputs may only be
          # depended upon by the current crate.
          private = bool;
        };
      });
      # Default outputs to use for specific build stages.
      default-outputs = {
        # Output used when building this crate as a dependency. Convention is
        # "lib" if present.
        lib = nullOr str;
        # Output used when building this crate as a binary. Convention is "bin"
        # if present.
        bin = nullOr str;
        # Output used to run a build script before the crate is built.
        # Convention is "prebuild" if present.
        prebuild = nullOr str;
        # Output used to run a build script after the crate is built.
        # Convention is "postbuild" if present.
        postbuild = nullOr str;
      };
    };
    # TODO: Assert correct crate types:
    # - default-outputs.lib needs to be a library crate type
    # - default-outputs.bin,prebuild,postbuild needs to be a bin crate
    postInstance =
      orig:
      let
        self = orig // {
          meta = orig.meta // {
            # rustc-safe version of the crate name
            name-rustc = replaceStrings [ "-" ] [ "_" ] orig.meta.name;
          };

          # Compile a build target of this crate for a specific target triple.
          compile =
            {
              # Name of the output to compile
              output,
              # Target triple to compile for
              target ? null,
              # If we're building in test mode
              test ? false,
              # Error format rustc should output
              error-format ? null,
              # Sysroot where rustc is located
              sysroot,
              # When true, creates a symlink in the output directory to the
              # toolchain sysroot, to prevent Nix from garbage-collecting the
              # toolchain.
              prevent-sysroot-gc ? true,
              # Output formats to emit
              emit ? [
                "link"
                "metadata"
              ],
              # Linker to use
              linker ? "${pkgs.gcc}/bin/cc",
            }@args:
            let
              output = self.outputs.${args.output};
              compiled = rustc {
                root = output.source;
                crate-name = self.meta.name-rustc;
                edition = fallback output.edition self.build-info.edition;
                inherit (output) crate-type;
                extern-crates =
                  (map (dep: {
                    name = dep.crate.meta.name-rustc;
                    path = "${
                      dep.crate.compile {
                        output = dep.output;
                        inherit target;
                        test = false;
                        inherit error-format sysroot;
                        emit = [
                          "link"
                          "metadata"
                        ];
                        inherit linker;
                      }
                    }/lib${dep.crate.meta.name-rustc}.rlib";
                  }) output.crate-dependencies)
                  ++ output.raw-crate-dependencies;
                inherit (output) search-paths native-libraries;
                inherit emit;
                inherit error-format;
                target = fallback target output.target;
                # TODO allow disabling the default test harness for tests
                # This would allow crates to instead provide their own test
                # harness
                build-test-harness = test;
                codegen =
                  {
                    embed-bitcode = false;
                  }
                  // (fallback output.codegen { })
                  // {
                    inherit linker;
                  };
                inherit sysroot;
              };
            in
            if prevent-sysroot-gc then
              derivation {
                name = self.meta.name;
                system = currentSystem;
                builder = "${pkgs.bash}/bin/bash";
                outputs = [ "out" ];
                args = [
                  "-c"
                  ''
                    mkdir -p $out
                    ln -s ${sysroot} $out/toolchain-sysroot
                    ln -s ${compiled}/* $out
                  ''
                ];
                PATH = "${pkgs.coreutils}/bin";
              }
            else
              compiled;
        };
      in
      self;
  };
in
crate-ty
