{ pkgs, ... }:
{
  config = {
    name = "link";
    version = "0.0.0";
    edition = 2024;

    dependencies = {
      liblua = {
        kind = "link";
        source = "${pkgs.lua54Packages.lua}/lib";
      };
    };
  };
}
