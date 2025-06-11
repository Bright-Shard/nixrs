# A semantic version: https://semver.org

{
  nixty,
  match,
  elemAt,
  ...
}:

with nixty.prelude;

newType {
  name = "semanticVersion";
  def = {
    major = int;
    minor = int;
    patch = int;
  };
  map =
    self:
    self
    // rec {
      regex = "^(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)$";

      fromString =
        val:
        let
          parsed = match regex val;
        in
        self {
          major = elemAt parsed 0;
          minor = elemAt parsed 1;
          patch = elemAt parsed 2;
        };
    };
}
