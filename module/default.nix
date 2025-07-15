{
  nixrs ? import ../nixrs { },
  crate-root,
  is-workspace-root ? false,
  module,
}:

let
  nixrs-with-module =
    nixrs
    // (
      let
        nixrs = nixrs-with-module;
      in
      {
        inherit nixrs;

        # Information about the crate specified in this Nix Module.
        CRATE-INFO = {
          inherit (module) config;
          inherit is-workspace-root crate-root;
        };

        # Custom option types used by the nixrs Nix Module.
        option-types = import ./types.nix nixrs;
        # The actual Nix module. Can be imported as a submodule.
        module = import ./options.nix nixrs;
        # Path to the toolchain installed by nixrs
        toolchain = nixrs.install-toolchain {
          inherit (module.config.workspace.toolchain)
            channel
            date
            profile
            components
            ;
          customTargetComponents = module.config.workspace.toolchain.custom-target-components;
        };
        # Takes a Nix module that sets nixrs' options, then
        # compiles the Rust project accordingly with nixrs' API.
        compile-module = import ./config/compile.nix nixrs;
        # Packages to add to a devshell for a nixrs project.
        shell-packages = import ./config/shell-packages.nix nixrs;
      }
    );
in

nixrs-with-module
