{ compileCrate, warn, ... }:
warn "This message appears because the custom build file is running!" compileCrate ./actual-crate
