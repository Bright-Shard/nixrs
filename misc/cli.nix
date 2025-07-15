# Nix file called by the nixrs CLI to build a crate.

{
  crate-root, # An absolute path to the root of the nixrs crate we're compiling.
  profile ? "debug", # The profile to compile the crate with.
  registries, # Crate registries that nixrs can download crates from.
  pkgs ? import <nixpkgs> { },
}:
let
  inherit (nixrs) fallback install-toolchain CURRENT-SYSTEM-RUST;
  nixrs = import ../nixrs { inherit registries pkgs; };
  crate = nixrs.parse-crate { inherit crate-root profile; };
  output = fallback crate.default-outputs.bin (
    fallback crate.default-outputs.lib (
      abort "Crate doesn't have any library or binary outputs, unsure how to proceed."
    )
  );
  # TODO check for rust-toolchain.toml and similar files
  toolchain = fallback crate.workspace-info.toolchain (install-toolchain {
    channel = "stable";
    profile = "nixrs-default";
  });
in
crate.compile {
  inherit output;
  test = false;
  sysroot = toolchain.${CURRENT-SYSTEM-RUST}.SYSROOT;
}
