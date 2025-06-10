{ ... }:
{
  name = "deps";
  version = "0.1.0";
  edition = 2024;

  dependencies = {
    some-lib = {
      source = ./some-lib;
    };
  };
}
