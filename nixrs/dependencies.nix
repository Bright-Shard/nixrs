{ warn, all, ... }:

dependencyConfig:

let
  dependency = import ./types/dependency;

  dependencies = [ ];
in
assert (all (val: dependency.isType val) dependencies);
warn "Dependencies not yet implemented, returning empty list..." [ ]
