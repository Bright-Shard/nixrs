{ ... }:
{
  # Intentionally invalid crate name, rustc will error if this "crate" ever gets
  # built
  name = "This should never build";
  version = "0.0.0";
  edition = 2024;
}
