# Downloads a Rust toolchain. Returns a table like so:
# ```nix
# {
#   <target triple> = {
#     SYSROOT = <store/path/to/sysroot>;
#     <component> = <store/path/to/extracted/component>;
#     <component2> = <store/path/to/extracted/component>;
#   };
# }
# ```
#
# nixrs downloads the already-published binaries for rustc, cargo, etc. This is
# different from the approach of nixpkgs or other Rust overlays, which tend to
# build these binaries from source. This is because nixrs aims to be painless,
# not pure or perfect.
#
# That being said, if nixrs gets lots of users in the future, it may be possible
# to get the best of both worlds by building and publishing binaries on sites
# like cachix.
#
#
#
# # How Rust Publishes Toolchains
#
# Rust publishes toolchains in a specific format that I couldn't find documented
# anywhere but have figured out from online resources and poking around. So I
# figured I would explain it here.
#
# All toolchains are published as TOML files served from
# `https://static.rust-lang.org/dist`. Each toolchain has its own TOML file,
# named `channel-rust-<toolchain channel here>.toml` - so, for example, the
# TOML file for the Rust nightly channel is at
# `https://static.rust-lang.org/dist/channel-rust-nightly.toml`. The TOML files
# for toolchains published on specific dates are stored in subdirectories named
# after the date they were published on. So, for example, you can find the TOML
# file for the Rust stable toolchain published on May 15th at
# `curl https://static.rust-lang.org/dist/2025-05-15/channel-rust-stable.toml`.
#
# Each toolchain's TOML file has the following keys:
#
# - `manifest-version`: String. Specifies the format for the toolchain file.
#   Is currently "2". Note that I haven't looked at any toolchains with
#   `manifest-version` 1, so I'm not sure how they differ.
#
# - `date`: String. Specifies the date the channel was published on.
#
# - `pkg`: Table. Stores components that can be installed on this toolchain.
#   Each entry in the `pkg` table is the name of the component
#   (e.g. `pkg.rustc` for the `rustc` component). Each entry is a subtable
#   with the following keys:
#     - `version`: String. The version of the component.
#     - `git_commit_hash`: String.
#     - `target`: Table. Each entry is a subtable that stores information
#       for a specific target triple, with the following keys:
#         - `available`: Boolean. If the component can be installed on the given
#           target triple.
#         - `url`: URL to a `.tar.gz` file where the component can be
#           downloaded.
#         - `hash`: SHA-256 hash of the `.tar.gz` file given in `url`.
#         - `xz_url`: URL to a `.tar.xz` file where the component can be
#           downloaded.
#         - `xz_hash`: SHA-256 hash of the `.tar.xz` file given in `xz_url`.
#         - `components`: Array of tables.
#   So, to check the version of `cargo` in a toolchain, you'd read
#   `pkg.cargo.version`. To download Cargo for a `x86_64-unknown-linux-gnu`
#   host, you'd download the file given in the URL in
#   `pkg.carg.target.x86_64-unknown-linux-gnu.url`, and then you could verify
#   the file's contents by checking that the file's SHA-256 hash matches the
#   hash in `pkg.carg.target.x86_64-unknown-linux-gnu.hash`.
#
# - `artifacts`: ??? Seems to be URLs for Windows installers
#
# - `renames`: Table. Renames components, e.g. it has an entry that renames
#   `clippy-preview` to `clippy`. Presumably this is for backwards
#   compatibility; the component that's currently called `clippy` was once
#   called `clippy-preview`, and is still listed in the `pkg` table as
#   `clippy-preview` so old code can find it. But the `renames` table changes
#   the name so the component is now called `clippy`. This allows new code to
#   refer to the component by its updated name.
#   The `renames` table is a table of tables. Each sub-table is named the new
#   name for the component (e.g. `renames.clippy`), and has a `to` key that
#   stores the old name (so `renames.clippy.to = "clippy-preview"`).
#
# - `profiles`: Table. These are the same as the profiles you can install with
#   rustup. Profiles are essentially groups of components, so you can install
#   the `minimal` profile instead of having to install the `rustc`, `cargo`,
#   `rust-std`, and `rust-mingw` components separately.
#   Each entry in the table is the name of the profile, and the value of each
#   entry is just an array of strings. Each string is a component to install.
#   So, for example,
#   `profiles.minimal = ["rustc", "cargo", "rust-std", "rust-mingw"]`.
#
#
#
# # Components Format
#
# Components are served compressed as `.tar.gz` or `.tar.xz` files (see above).
# Each component will have a `install.sh` file to install the component. This
# script will copy all of the needed files to install the given component. Run
# `./install.sh` to install the component system-wide; `./install.sh --help` to
# see options for installing the component elsewhere.

{
  pkgs,
  lib,
  nixty,
  hasAttr,
  listToAttrs,
  mapAttrs,
  getAttr,
  attrValues,
  filter,
  elem,
  fetchurl,
  download,
  CURRENT-SYSTEM-RUST,
  ...
}:

let
  args-ty =
    with nixty.prelude;
    newType {
      name = "install-toolchain-args";
      def = {
        # The channel to download
        channel = oneOfVal [
          "stable"
          "beta"
          "nightly"
        ];
        # Download the toolchain published on a specific date
        # If null, nixrs will install the latest version of the toolchain
        date = nullOr str;
        # The target to install the toolchain for
        target = withDefault CURRENT-SYSTEM-RUST str;
        # The components profile to install (minimal, default, complete)
        # If null, no profile will be installed, and only the components in the
        # components arg will be installed
        profile = nullOr (oneOfVal [
          "minimal"
          "default"
          "complete"
          "nixrs-default"
        ]);
        # Components to install - these are installed in addition to any
        # components that are installed from the specified profile (if there
        # was one)
        components = withDefault [ ] list;
        # Additional components to install for foreign targets (i.e. not the
        # host system's target). The format is
        # `<target> = [ "component1" "component2" ]`.
        #
        # For example, you could download the standard library for cross
        # compilation to WASM like so:
        # ```nix
        # custom-target-components = {
        #   wasm32-unknown-unknown = [ "std" ];
        # };
        # ```
        custom-target-components = withDefault { } set;
      };
    };
in

args-raw:

let
  inherit (lib.trivial) importTOML;
  inherit (pkgs.stdenvNoCC) mkDerivation;
  inherit (pkgs) symlinkJoin;

  args = args-ty args-raw;

  # Additional toolchain profiles nixrs adds. They're meant to be more sensible
  # defaults for nixrs, which doesn't need some components like Cargo.
  nixrs-profiles = {
    nixrs-default = [
      "rustc"
      "rust-src"
      "rust-std"
      "rust-docs"
      "rustfmt-preview"
      "clippy-preview"
    ];
  };

  url =
    if args.date == null then
      "https://static.rust-lang.org/dist/channel-rust-${args.channel}.toml"
    else
      "https://static.rust-lang.org/dist/${args.date}/channel-rust-${args.channel}.toml";
  toolchain-name = "rust-${args.channel}${
    if args.date != null then "-${args.date}-" else ""
  }-toolchain";
  raw-cfg = (importTOML (fetchurl url));
  cfg = raw-cfg // {
    profiles = raw-cfg.profiles // nixrs-profiles;
  };

  component-exists-for-host =
    component:
    hasAttr args.target cfg.pkg.${component}.target || hasAttr "*" cfg.pkg.${component}.target;
  hostComponents =
    if args.profile == null then
      args.components
    else
      args.components ++ (filter component-exists-for-host cfg.profiles.${args.profile});
  # { target-triple = ["component", "component"]; }
  all-components = args.custom-target-components // {
    ${args.target} = hostComponents;
  };

  # Resolves the component's actual name from the renames table, adds any
  # additional dependencies for that component (e.g. clippy depends on the
  # rustc component), then downloads the component's tar file and installs it
  # into an isolated derivation.
  get-component =
    target-triple: component-alias:
    let
      component-name =
        if hasAttr component-alias cfg.pkg then
          toString component-alias
        else if hasAttr component-alias cfg.renames then
          cfg.renames.${component-alias}.to
        else
          abort "Couldn't find component `${component-alias}`.";
      pkg = getAttr component-name cfg.pkg;
      component =
        if hasAttr args.target pkg.target then
          pkg.target.${args.target}
        else if hasAttr "*" pkg.target then
          pkg.target."*"
        else
          abort "Couldn't install component ${component-alias} for target ${args.target}";
      deps =
        with pkgs;
        if
          elem component-name [
            "clippy-preview"
            "rustfmt-preview"
            "rustc-codegen-cranelift-preview"
            "miri-preview"
            "rust-analyzer-preview"
          ]
        then
          [ (get-component target-triple "rustc") ]
        else if
          elem component-name [
            "cargo"
            "rust-std"
          ]
        then
          [ libgcc ]
        else if component-name == "rustc" then
          [
            libgcc
            libz
          ]
        else if component-name == "rustc-dev" then
          [
            libgcc
            libz
            "${get-component target-triple "llvm-tools-preview"}/lib/rustlib/${target-triple}"
          ]
        else if component-name == "llvm-tools-preview" then
          [
            libz
            libgcc
          ]
        else
          [ ];
      tar-file =
        if component.available then
          download {
            name = "${toolchain-name}-${component-name}";
            url = component.xz_url;
            hash = component.xz_hash;
          }
        else
          abort "The component `${component-name}` isn't available for the target `${args.target}`.";
    in
    mkDerivation {
      name = "${toolchain-name}-${component-name}-unpack";
      system = builtins.currentSystem;
      dontUnpack = true;
      outputs = [
        "out"
      ];
      postBuild = ''
        tar -xf ${tar-file} -C . --strip-components=1
        bash ./install.sh --disable-ldconfig --disable-verify --destdir=$out --prefix=
      '';

      buildInputs = deps ++ [ pkgs.autoPatchelfHook ];
    };

  # Takes the derivations from all installed components and symlinks them
  # together to form a sysroot.
  build-sysroot =
    target: components:
    symlinkJoin {
      name = toolchain-name;
      paths = components;
    };
in

assert cfg.manifest-version == "2";

mapAttrs (
  target-triple: component-list:
  let
    components = listToAttrs (
      map (component: {
        name = component;
        value = get-component target-triple component;
      }) component-list
    );
  in
  components // { SYSROOT = build-sysroot target-triple (attrValues components); }
) all-components
