# nixty schema
#
# There are two kinds of nixty values: Types, and type instances. Types are the
# actual definitions of a type that can be built. Type instances are
# type-checked values that follow a type.
#
# Types fall into two categories: primitives and user types. Primitives are
# built-in Nix types, like string, int, etc. User types are sets with specific
# required fields. So, user types are sets while primitives are other values.
#
# Type instances follow this schema:
# {
#   __nixty: str, # name of the type this is an instance of
#   __nixty_meta: set, # stores the type this instance was created from
#   ... # all the appropriate fields for this type
# }
#
# User types follow this schema:
# {
#   __nixty: str, # name of this type
#   __nixty_type = null, # marker field, only present for primitives & types
#   __nixty_typedef: set, # the type definition, null for primitives
#   __functor: lambda, # builds an instance of this type
# }
#
# Primitive types have all of the user type fields, plus the following fields:
# {
#   __nixty_primitive = null, # marker field, only present for primitives
#   __nixty_check: lambda, # verifies a value is the primitive type
#   __nixty_errctx: lambda, # Error message to show for invalid type errors
# }
let
  inherit (builtins)
    typeOf
    elem
    all
    any
    attrNames
    addErrorContext
    seq
    deepSeq
    mapAttrs
    toJSON
    concatStringsSep
    ;
in
rec {
  # Everything you need to use nixty.
  prelude = primitives // {
    inherit isType newType;
  };

  # Simple function to get the nixty type of a value, falling back to the
  # built-in typeOf function if the value isn't a nixty type.
  type = val: if val ? __nixty then val.__nixty else typeOf val;
  # Test if a value is an instance of a type.
  isType =
    val: ty:
    let
      isPrim = ty ? __nixty_primitive;
    in
    if isPrim then
      ty.__nixty_check val
    else if val ? __nixty then
      val.__nixty == ty.__nixty
    else if typeOf val == "set" && !isPrim then
      seq (ty val) true
    else
      false;
  # Define a new nixty type.
  newType =
    {
      name,
      def,
      map ? self: self,
    }:
    let
      assertSchema =
        set:
        assert typeOf set == "set";
        all (
          key:
          let
            val = set.${key};
          in
          if val ? __nixty_type then
            true
          else if typeOf val == "set" then
            assertSchema val
          else
            abort "The field `${key}` isn't set to a valid type."
        ) (attrNames set);
    in
    addErrorContext "While creating the nixty type `${name}`" (
      deepSeq (assertSchema def) (map {
        __nixty = name;
        __nixty_type = null;
        __nixty_typedef = def;
        __functor =
          self: val:

          if typeOf val != "set" then
            abort "nixty error: Tried to instantiate the type `${name}`, but didn't pass a set of fields"
          else if val ? __nixty && val.__nixty == name then
            val
          else
            let
              buildSet =
                name: set: val:
                mapAttrs (
                  key: ty:
                  addErrorContext "While type-checking the field `${key}` of `${name}`" (
                    if ty ? __nixty_type then ty (val.${key} or null) else buildSet "${name}.${key}" ty val.${key}
                  )
                ) set;
            in
            buildSet name def val;
      })
    );
  # Define a new nixty primitive.
  newPrimitive = name: check: {
    __nixty = name;
    __nixty_type = null;
    __nixty_primitive = null;
    __nixty_typedef = null;
    __nixty_check = check;
    __functor =
      self: val: if !(check val) then abort "nixty type error: ${self.__nixty_errctx val}" else val;
    __nixty_errctx = val: "Expected a `${name}` value, got a `${type val}` value";
  };

  primitives = {
    # Any value.
    any = newPrimitive "any" (val: true);
    # A string.
    str = newPrimitive "str" (val: typeOf val == "string");
    # A boolean.
    bool = newPrimitive "bool" (val: typeOf val == "bool");
    # A derivation.
    derivation = newPrimitive "derivation" (val: val ? type && val.type == "derivation");
    # An attribute set.
    set = newPrimitive "set" (val: typeOf val == "set");
    # An attribute set where every value in the set is a specific type.
    setOf =
      ty:
      assert ty ? __nixty_type;
      newPrimitive "set-of-${ty.__nixty}" (
        val: typeOf val == "set" && all (key: isType val.${key} ty) (attrNames val)
      );
    # A path. This only accepts literal path values.
    pathStrict = newPrimitive "pathStrict" (val: typeOf val == "path");
    # A type that can be coerced to a path - paths, strings, and derivations.
    path = newPrimitive "path" (
      val:
      let
        ty = typeOf val;
      in
      ty == "string" || ty == "path" || (val ? type && val.type == "derivation")
    );
    # A list.
    list = newPrimitive "list" (val: typeOf val == "list");
    # A list where every value is a specific type.
    listOf =
      ty:
      assert ty ? __nixty_type;
      newPrimitive "list-of-${ty.__nixty}" (val: typeOf val == "list" && all (val: isType val ty) val);
    # A type that can be coerced to a function - functions/lambdas and functor
    # sets.
    func = newPrimitive "func" (val: typeOf val == "lambda" || val ? __functor);
    # A function. This only accepts literal functions/lambdas, not functor sets.
    funcStrict = newPrimitive "funcStrict" (val: typeOf val == "lambda");
    # An integer (number without a decimal).
    int = newPrimitive "int" (val: typeOf val == "int");
    # A float (number with a decimal).
    float = newPrimitive "float" (val: typeOf val == "float");
    # A number - an integer or a float, a number with or without a decimal.
    num = newPrimitive "num" (
      val:
      elem (typeOf val) [
        "int"
        "float"
      ]
    );
    # A null value.
    null = newPrimitive "null" (val: val == null);
    # Either null or the given type.
    nullOr =
      ty:
      assert ty ? __nixty_type;
      let
        primitive = newPrimitive "null-or-${ty.__nixty}" (val: val == null || (isType val ty));
      in
      primitive // { __functor = self: val: if val == null then null else ty val; };
    # One of the values given in a specific list.
    oneOfVal =
      validValues:
      (newPrimitive "one-of-val" (val: elem val validValues))
      // {
        __nixty_errctx = val: "Expected one of ${toJSON validValues}, got ${toJSON val}";
      };
    # Any value whose type is in the given list.
    oneOfTy =
      validTypes:
      newPrimitive "one-of-type" (val: any (ty: isType val ty) validTypes)
      // {
        __nixty_errctx =
          val:
          "Expected one of the types [${
            concatStringsSep ", " (map (ty: "`${ty.__nixty}`") validTypes)
          }], got type `${type val}`";
      };
    # A nixty type, falling back to a default value if the value isn't given.
    withDefault =
      default: ty:
      assert ty ? __nixty_type;
      assert isType default ty;
      let
        primitive = (newPrimitive "${ty.__nixty}-default" (val: val == null || isType val ty));
      in
      primitive // { __functor = self: val: if val == null then default else ty val; };
  };
}
