let
  nixty = import ./.;
in
with nixty;

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
  assert isType null primitives.null;

  # Validate advanced primitives
  assert isType {
    one = true;
    two = false;
  } (setOf bool);
  assert isType true (nullOr bool);
  assert isType null (nullOr bool);
  assert isType true (oneOfTy [
    bool
    str
  ]);
  assert isType "str" (oneOfTy [
    bool
    str
  ]);
  assert
    !(isType 1 (oneOfType [
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

  true
);

"tests passed :D"
