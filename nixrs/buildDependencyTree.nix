# Takes a list of dependencies and builds a complete dependency tree from that
# list.

with builtins;

dependencies:
let
  dependency = import ./types/dependency;
in
assert (all (val: dependency.isType val) dependencies);
abort "todo: dependencies"
