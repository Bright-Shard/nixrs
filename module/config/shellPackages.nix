{
  package,
  toolchain,
  pkgs,
  currentSystemRust,
  ...
}:
# TODO add binary dependencies
[
  (pkgs.callPackage package { })
  toolchain.${currentSystemRust}.SYSROOT
]
