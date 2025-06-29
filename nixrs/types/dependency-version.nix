{
  lib,
  match,
  elemAt,
  nixty,
  types,
  ...
}:

with nixty.prelude;

let
  inherit (types) semantic-version;
  toInt = lib.strings.toIntBase10;
in

newType {
  name = "dependency-version";
  def = {
    min = semantic-version;
    max = semantic-version;
  };
  postType =
    self:
    self
    // rec {
      regex = "^([=<>\\^~]|<=|>=)?(0|[1-9][0-9]*|\\*)\\.?(0|[1-9][0-9]*|\\*)?\\.?(0|[1-9][0-9]*|\\*)?$";

      from-string =
        val:

        let
          parsed = match regex val;
          requirement = elemAt parsed 0;
          rawMajor = elemAt parsed 1;
          rawMinor = elemAt parsed 2;
          rawPatch = elemAt parsed 3;
        in
        if parsed == null then
          abort "Invalid dependency version: ${val}"
        else if rawMajor == "*" || rawMinor == "*" || rawPatch == "*" then
          if requirement != null then
            abort "Cannot have wildcard dependency versions and another version requirement"
          else
            abort "TODO: Wildcard dep versions"
        else
          let
            major = toInt rawMajor;
            minor = if rawMinor == null then 0 else toInt rawMinor;
            patch = if rawPatch == null then 0 else toInt rawPatch;
            specifiedVersion = semantic-version {
              inherit major;
              inherit minor;
              inherit patch;
            };
          in
          if requirement == "^" || requirement == null then
            if major == 0 then
              if rawMinor == null then
                # 0
                self {
                  min = specifiedVersion;
                  max = semantic-version {
                    major = 1;
                    minor = 0;
                    patch = 0;
                  };
                }
              else if minor == 0 then
                if rawPatch == null then
                  # 0.0
                  self {
                    min = specifiedVersion;
                    max = semantic-version {
                      major = 0;
                      minor = 1;
                      patch = 0;
                    };
                  }
                else if patch == 0 then
                  # The Cargo book actually doesn't list an example for 0.0.0, so
                  # this is based off of the behaviour of 0 and 0.0
                  self {
                    min = specifiedVersion;
                    max = semantic-version {
                      major = 0;
                      minor = 0;
                      patch = 1;
                    };
                  }
                else
                  # 0.0.x
                  self {
                    min = specifiedVersion;
                    max = semantic-version {
                      major = 0;
                      minor = 0;
                      patch = patch + 1;
                    };
                  }
              else
                # 0.x
                self {
                  min = specifiedVersion;
                  max = semantic-version {
                    major = 0;
                    minor = minor + 1;
                    patch = 0;
                  };
                }
            else
              # x
              self {
                min = specifiedVersion;
                max = semantic-version {
                  major = major + 1;
                  minor = 0;
                  patch = 0;
                };
              }
          else if requirement == "~" then
            abort "TODO: tilde dep versions"
          else if requirement == "=" then
            self {
              min = specifiedVersion;
              max = specifiedVersion;
            }
          else
            abort "TODO: comparison dep versions";
    };
}
