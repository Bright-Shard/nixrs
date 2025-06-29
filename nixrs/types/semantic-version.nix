{
  nixty,
  match,
  elemAt,
  fromJSON,
  ...
}:

with nixty.prelude;

newType {
  name = "semantic-version";
  def = {
    major = int;
    minor = int;
    patch = int;
  };
  postType =
    self:
    self
    // rec {
      regex = "^(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)$";

      from-string =
        val:
        let
          parsed = match regex val;
        in
        self {
          major = fromJSON (elemAt parsed 0);
          minor = fromJSON (elemAt parsed 1);
          patch = fromJSON (elemAt parsed 2);
        };
    };
}
