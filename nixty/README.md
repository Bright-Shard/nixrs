# nixty - nifty typing for Nix

nixty aims to provide a simple API for type-checking in pure Nix. Types can be declared similarly to types in NixOS' module system, and types can be checked with a single function.

## example

```nix
let
  # Importing nixty is dead-simple
  nixty = import /path/to/nixty;
  # Declare new types with a name and a definition schema
  person = nixty.newType {
    name = "person";
    def = with nixty.primitives; {
      # Basic types
      name = str;
      # Optional values
      gender = nullOr str;
      # Default values - this field will be 18 if unspecified
      age = withDefault 18 int;
    };
  };
in

let
  # Types double as functions, which makes instantiating them very simple
  brightShard = person {
    name = "BrightShard";
    gender = "???";
    age = 18;
  };
  # Of course, optional fields don't need to be specified
  optional = person { name = "optional"; };
in
assert brightShard.name == "BrightShard";
assert optional.gender == null;
assert optional.age == 18;

# Checking types is also super simple
assert nixty.isType brightShard person;

true
```


## speed

Because it's written in pure Nix, nixty will slow down evaluation time. Ideally, the Nix evaluator will eventually get built-in type checking written in C++.

The hundred-line test suite found in `test.nix` runs in .024s on my system (ran with `time nix repl --file test.nix --show-trace`). This is the exact same amount of time it takes to run `empty.nix` with the same command. So nixty will not add any noticeable overhead to your Nix program.
