# A semantic version: https://semver.org

{ mkType, ... }:

mkType {
  typeName = "semanticVersion";
  schema = {
    major = "int";
    minor = "int";
    patch = "int";
  };
}
