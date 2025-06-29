let
  inherit (nixty)
    primitives
    newType
    isType
    type
    ;
  inherit (builtins) attrNames elemAt;

  nixty = import ./.;
in

assert (
  with primitives;

  # Validate primitives
  assert isType "test123" str;
  assert !(isType 1 str);
  assert isType true bool;
  assert isType { } set;
  assert isType ./. path;
  assert isType [ ] list;
  assert isType (x: x) func;
  assert isType { __functor = self: self; } func;
  assert isType 1 int;
  assert isType 1.5 float;
  assert isType 1 num;
  assert isType 1.5 num;
  assert isType builtins.null primitives.null;
  assert !(isType builtins.null int);

  # Validate advanced primitives
  assert isType {
    one = true;
    two = false;
  } (setOf bool);
  assert isType true (nullOr bool);
  assert isType builtins.null (nullOr bool);
  assert isType true (oneOfTy [
    bool
    str
  ]);
  assert isType "str" (oneOfTy [
    bool
    str
  ]);
  assert
    !(isType 1 (oneOfTy [
      bool
      str
    ]));
  assert isType 1 (oneOfVal [
    1
    2
    3
  ]);
  assert isType 2 (oneOfVal [
    1
    2
    3
  ]);
  assert
    !(isType 0 (oneOfVal [
      1
      2
      3
    ]));
  assert isType false (withDefault true bool);
  assert isType null (withDefault true bool);
  assert (withDefault true bool) false == false;
  assert (withDefault true bool) null == true;

  true
);
# Validate custom types
assert (
  let
    person = newType {
      name = "person";
      def = with primitives; {
        name = str;
        age = withDefault 18 num;
        gender = nullOr str;
      };
    };
  in

  # Check Nixty type fields
  assert person.__nixty == "person";
  assert person.__nixty_type == null;
  assert type person.__nixty_typedef == "set";
  assert
    attrNames person.__nixty_typedef == [
      "age"
      "gender"
      "name"
    ];

  # Check building the custom type
  assert isType {
    name = "Billy Bob Joe";
    age = 69;
    gender = null;
  } person;
  assert
    (person {
      name = "Jilly Job Boe";
      age = 420;
      gender = "hi";
    }).age == 420;
  assert isType (person {
    name = "Speykious";
    age = 727;
    gender = "egg";
  }) person;
  assert
    (person {
      name = "Ageless";
    }).age == 18;
  assert
    (person {
      name = "Ageless";
    }).gender == null;

  # Check Nixty type instance fields
  let
    personInstance = person {
      name = "E";
    };
  in
  assert personInstance.__nixty == "person";
  assert personInstance.__nixty == person.__nixty;
  assert personInstance.__nixty_meta == person;
  assert
    attrNames (nixty.strip personInstance) == [
      "age"
      "gender"
      "name"
    ];

  true
);
# Check that Nixty.isType catches errors
# This performs two tests:
# 1. Nixty catches errors as expected
# 2. isType does not error, and only ever returns true/false
assert (
  let
    crate = newType {
      name = "crate";
      def = with primitives; {
        version = int;
        meta = {
          name = str;
          author = str;
        };
      };
    };
  in

  assert
    !(isType {
      # Missing all fields
    } crate);
  assert
    !(isType {
      version = 1;
      # Missing field meta
    } crate);
  assert
    !(isType {
      version = 1;
      meta = {
        # Missing fields name, author
      };
    } crate);
  assert
    !(isType {
      version = 1;
      meta = {
        # Incorrect type, missing field author
        name = true;
      };
    } crate);
  assert
    !(isType {
      version = 1;
      meta = {
        name = "my-crate";
        # Missing field author
      };
    } crate);
  assert
    !(isType {
      version = 1;
      meta = {
        name = "my-crate";
        # Incorrect type for author
        author = true;
      };
    } crate);
  assert
    !(isType {
      version = 1;
      meta = {
        name = true;
        # Incorrect type for name
        author = "john doe";
      };
    } crate);

  # Correct
  assert isType {
    version = 1;
    meta = {
      name = "my-crate";
      author = "john doe";
    };
  } crate;

  true
);
# Other edge cases
assert (
  let
    type = newType {
      name = "typeAcceptingNull";
      def = with primitives; {
        field = nullOr str;
      };
    };
  in
  assert (type { }).field == null;
  assert (type { field = "hi"; }).field == "hi";

  let
    listTy = newType {
      name = "listOfTypeAcceptingNull";
      def = with primitives; {
        list = listOf type;
      };
    };
    list = listTy { list = [ { } ]; };
    listElem = elemAt list.list 0;
  in
  assert listElem ? field;
  assert listElem.field == null;

  true
);

"tests passed :D"
