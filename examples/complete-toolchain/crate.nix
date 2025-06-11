{ ... }:
{
  name = "complete_toolchain";
  version = "0.0.0";
  edition = 2024;

  workspace.toolchain = {
    channel = "nightly";
    profile = "complete";
  };
}
