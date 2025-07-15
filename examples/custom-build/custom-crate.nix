{ nixrs, warn, ... }:

warn "This message appears because the custom build file is running!" (
  nixrs.parse-crate { crate-root = ./actual-crate; }
)
