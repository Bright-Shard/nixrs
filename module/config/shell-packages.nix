{
  package,
  toolchain,
  pkgs,
  CURRENT-SYSTEM-RUST,
  ...
}:
# TODO add binary dependencies
[
  (pkgs.callPackage package { })
  toolchain.${CURRENT-SYSTEM-RUST}.SYSROOT
]
