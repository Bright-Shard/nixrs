# A semantic version: https://semver.org

{
  mkType,
  match,
  elemAt,
  ...
}:

mkType {
  typeName = "semanticVersion";
  schema = {
    major = "int";
    minor = "int";
    patch = "int";
  };
  addFields = self: rec {
    regex = "^(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)$";

    fromString =
      val:
      let
        parsed = match regex val;
      in
      self.build {
        major = elemAt parsed 0;
        minor = elemAt parsed 1;
        patch = elemAt parsed 2;
      };
  };
}
