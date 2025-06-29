{ ... }:
{
  name = "complete_toolchain";
  version = "0.0.0";
  edition = 2024;

  dev-env.toolchain = {
    channel = "nightly";
    profile = "complete";
  };
}
