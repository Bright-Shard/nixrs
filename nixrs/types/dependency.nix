{ nixty, types, ... }:

with nixty.prelude;
newType {
  name = "dependency";
  def = {
    # The crate being depended on.
    crate = unsafeAssumeTy types.crate;
    # The output of the crate being depended on.
    output = str;
    # The max and min acceptable versions of the dependency.
    version = nullOr types.dependency-version;
    # Feature flags enabled for the dependency.
    enabled-features = listOf str;
  };
}
