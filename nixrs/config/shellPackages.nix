{
  package,
  toolchain,
  pkgs,
  currentSystemRust,
  ...
}:
[
  (pkgs.callPackage package { })
  toolchain.${currentSystemRust}.SYSROOT
]
