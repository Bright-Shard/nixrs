{
  nixrs ? import ../nixrs { },
  workspaceRoot,
  module,
}:
let
  nixrsWithModule =
    nixrs
    // (
      let
        nixrs = nixrsWithModule;
      in
      {
        inherit nixrs;
        inherit workspaceRoot;
        inherit (module) config;

        # Custom option types used by the nixrs Nix Module.
        optionTypes = import ./types.nix nixrs;
        # The actual Nix module. Can be imported as a submodule.
        module = import ./options nixrs;
        # Path to the toolchain installed by nixrs
        toolchain = nixrs.installToolchain {
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
        compileModule = import ./config/compile.nix nixrs;
        # Packages to add to a devshell for a nixrs project.
        shellPackages = import ./config/shellPackages.nix nixrs;
        # Converts an attribute set of dependencies to a list of
        # compilation settings.
        dependenciesToCompilationSettings = import ./config/depsToCompSettings.nix nixrs;
      }
    );
in
nixrsWithModule
