{
  package,
  workspace,
  pkgs,
  currentSystemRust,
  ...
}:
# TODO add binary dependencies
[
  (pkgs.callPackage package { })
  workspace.toolchain.${currentSystemRust}.SYSROOT
]
