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
  currentSystemRust,
  pkgs,
  lib,
  fetchurl,
  hasAttr,
  listToAttrs,
  mapAttrs,
  getAttr,
  download,
  attrValues,
  filter,
  ...
}:

{
  # The channel to download (stable, beta, nightly)
  channel,
  # Optional - download the toolchain published on a specific date
  # If null, nixrs will install the latest version of that toolchain
  date ? null,
  # The target to install the toolchain for
  target ? currentSystemRust,
  # Optional - the components profile to install (minimal, default, complete)
  # If null, no profile will be installed, and only the components in the
  # components arg will be installed
  profile ? "default",
  # Components to install - these are installed in addition to any components
  # that are installed from the specified profile (if there was one)
  components ? [ ],
  # Additional components to install for foreign targets (i.e. not the host
  # system's target). The format is `<target> = [ "component1" "component2" ]`.
  #
  # For example, you could download the standard library for cross compilation
  # to WASM like so:
  # ```nix
  # customTargetComponents = {
  #   wasm32-unknown-unknown = [ "std" ];
  # };
  # ```
  customTargetComponents ? { },
}:

let
  inherit (lib.trivial) importTOML;
  inherit (pkgs.stdenvNoCC) mkDerivation;

  url =
    if date == null then
      "https://static.rust-lang.org/dist/channel-rust-${channel}.toml"
    else
      "https://static.rust-lang.org/dist/${date}/channel-rust-${channel}.toml";
  cfg = importTOML (fetchurl url);

  componentExistsForHost = component: hasAttr target cfg.pkg.${component}.target;
  hostComponents =
    if profile == null then
      components
    else
      components ++ (filter componentExistsForHost cfg.profiles.${profile});
  # { target-triple = ["component", "component"]; }
  allComponents = customTargetComponents // {
    ${target} = hostComponents;
  };

  toolchainName = "rust-${channel}${if date != null then "-${date}-" else ""}-toolchain";

  unpackComponent =
    componentName: src:
    derivation {
      name = "${toolchainName}-${componentName}-extract";
      system = builtins.currentSystem;
      outputs = [ "out" ];
      builder = "${pkgs.gnutar}/bin/tar";
      args = [
        "-xf"
        src
        "--one-top-level=${placeholder "out"}"
        "--strip-components=1"
      ];
      PATH = "${pkgs.xz}/bin";
    };
  downloadComponent =
    target: componentName:
    let
      pkg =
        if hasAttr componentName cfg.pkg then
          cfg.pkg.${componentName}
        else if hasAttr componentName cfg.renames then
          getAttr cfg.renames.${componentName}.to cfg.pkg
        else
          abort "Couldn't find component `${componentName}`.";
      component = pkg.target.${target};
    in
    if component.available then
      download {
        name = "${toolchainName}-${componentName}";
        url = component.xz_url;
        hash = component.xz_hash;
      }
    else
      abort "The component `${componentName}` isn't available for the target `${target}`.";
  buildSysroot =
    target: components:
    mkDerivation {
      name = toolchainName;
      system = builtins.currentSystem;
      outputs = [ "out" ];

      dontUnpack = true;
      postBuild = ''
        for componentSrc in $components; do
          bash $componentSrc/install.sh --disable-ldconfig --disable-verify --destdir=$out --prefix=
          # Slightly hacky, but each install script tries to put an uninstall
          # script in the same location, which causes errors. We don't even
          # need the uninstall script since the sysroot can be ditched by
          # deleting it from the store.
          rm $out/lib/rustlib/uninstall.sh
        done
      '';
      inherit components;

      buildInputs = with pkgs; [
        autoPatchelfHook
        libgcc
        libz
      ];
    };
in

assert cfg.manifest-version == "2";

mapAttrs (
  targetTriple: componentList:
  let
    components = listToAttrs (
      map (component: {
        name = component;
        value = unpackComponent component (downloadComponent targetTriple component);
      }) componentList
    );
  in
  components // { SYSROOT = buildSysroot targetTriple (attrValues components); }
) allComponents
