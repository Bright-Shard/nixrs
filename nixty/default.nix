# Nixty schema
#
# There are two kinds of Nixty values: Types, and type instances. Types are the
# actual definitions of a type that can be built. Type instances are
# type-checked values that follow a type.
#
# Types fall into two categories: primitives and user types. Primitives are
# built-in Nix types, like string, int, etc. User types are sets with specific
# required fields. So, user types are sets while primitives are other values.
#
# Type instances have all of these fields:
# {
#   __nixty: str, # name of the type this is an instance of
#   __nixty_meta: set, # stores the type this instance was created from
#   ... # all the appropriate fields for this type
# }
#
# User types have all of these fields:
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
    elemAt
    length
    all
    any
    tryEval
    attrNames
    removeAttrs
    addErrorContext
    seq
    deepSeq
    mapAttrs
    toJSON
    concatStringsSep
    ;
in
rec {
  # Everything you need to use Nixty.
  prelude = primitives // {
    inherit isType newType primitives;
  };

  # Simple function to get the Nixty type of a value, falling back to the
  # built-in typeOf function if the value isn't a Nixty type.
  type = val: if val ? __nixty then val.__nixty else typeOf val;
  # Test if a value is an instance of a Nixty type. This function will throw
  # an error if the value passed for the type argument is not a Nixty type.
  isType =
    val: ty:
    let
      isPrim = ty ? __nixty_primitive;
    in
    if !(ty ? __nixty_type) then
      throw "Nixty.isType: The type argument is not a Nixty type. Nixty cannot type-check against it."
    else if val ? __nixty then
      (val.__nixty == ty.__nixty)
    else if isPrim then
      (ty.__nixty_check val)
    else if typeOf val == "set" && !isPrim then
      (tryEval (deepSeq (ty val) (ty val))).success
    else
      false;
  # Removes all the Nixty-specific fields from a Nixty primitive, type, or type
  # instance.
  strip = val: stripInstance (stripPrimitive val);
  # Remove fields specific to Nixty type instances from the given attribute set.
  stripInstance =
    val:
    removeAttrs val [
      "__nixty"
      "__nixty_meta"
    ];
  # Remove fields specific to Nixty types from the given attribute set.
  stripType =
    val:
    removeAttrs val [
      "__nixty"
      "__nixty_type"
      "__nixty_typedef"
      "__functor"
    ];
  # Remove fields specific to Nixty primitives from the given attribute set.
  stripPrimitive =
    val:
    removeAttrs (stripType val) [
      "__nixty_errctx"
      "__nixty_check"
      "__nixty_primitive"
    ];

  # Define a new Nixty type.
  newType =
    {
      # Name of the new type.
      name,
      # The new type's definition/schema.
      def,
      # Function that runs after the type table is built.
      postType ? self: self,
      # Function that runs after an instance of the type is built.
      postInstance ? self: self,
    }:
    addErrorContext "While creating the Nixty type `${name}`" (
      let
        assertSchema =
          name: set:
          assert typeOf set == "set";
          seq (all (
            key:
            let
              val = set.${key};
            in
            if val ? __nixty_type then
              true
            else if typeOf val == "set" then
              assertSchema "${name}.${key}" val
            else
              throw "The field `${name}.${key}` isn't set to a valid type."
          ) (attrNames set)) true;

        builtType = postType {
          __nixty = name;
          __nixty_type = null;
          __nixty_typedef = def;
          __functor =
            self: val:

            if typeOf val != "set" then
              throw "Nixty type error: Expected a set to be passed when instantiating the type `${name}`; instead got the type `${typeOf val}`"
            else if val ? __nixty && val.__nixty == name then
              val
            else
              let
                validateSet =
                  typeName: typeDefinition: val:
                  mapAttrs (
                    key: ty:
                    addErrorContext "While type-checking the field `${key}` of `${typeName}`" (
                      if ty ? __nixty_type then
                        ty (val.${key} or null)
                      else if val ? ${key} then
                        validateSet "${typeName}.${key}" ty val.${key}
                      else
                        throw "Nixty type error: Missing the field `${key}` when trying to instantiate the type `${name}`"
                    )
                  ) typeDefinition;
                validated = validateSet name def val;
                instance = postInstance (
                  validated
                  // {
                    __nixty = name;
                    __nixty_meta = self;
                  }
                );
              in
              instance;
        };
      in
      seq (assertSchema name def) builtType
    );

  # Define a new Nixty primitive.
  newPrimitive = name: check: {
    __nixty = name;
    __nixty_type = null;
    __nixty_primitive = null;
    __nixty_typedef = null;
    __nixty_check = check;
    __functor =
      self: val:
      if self.__nixty_check val then val else throw "Nixty type error: ${self.__nixty_errctx val}";
    __nixty_errctx = val: "Expected a `${name}` value, got a `${type val}` value";
  };

  primitives = {
    # Any value.
    any = newPrimitive "any" (val: true);
    # A type that can be coerced to a string - a string literal, or a set with
    # `__toString`, or a set with `outPath`.
    str = newPrimitive "str" (val: typeOf val == "string" || val ? __toString || val ? outPath);
    # A string. This only accepts string literals.
    strStrict = newPrimitive "strStrict" (val: typeOf val == "string");
    # A boolean.
    bool = newPrimitive "bool" (val: typeOf val == "bool");
    # A derivation.
    drv = newPrimitive "drv" (val: val ? type && val.type == "derivation");
    # An attribute set.
    set = newPrimitive "set" (val: typeOf val == "set");
    # An attribute set where every value in the set is a specific type.
    setOf =
      ty:
      assert ty ? __nixty_type;
      (newPrimitive "setOf-${ty.__nixty}" (
        val: typeOf val == "set" && all (key: isType val.${key} ty) (attrNames val)
      ))
      // {
        __functor =
          self: val:
          if typeOf val == "set" then
            mapAttrs (key: val: ty val) val
          else
            throw "Nixty type error: ${self.__nixty_errctx val}";
      };
    # A type that can be coerced to a path - paths, strings, and derivations.
    path = newPrimitive "path" (
      val:
      let
        ty = typeOf val;
      in
      ty == "string" || ty == "path" || (val ? type && val.type == "derivation")
    );
    # A path. This only accepts literal path values.
    pathStrict = newPrimitive "pathStrict" (val: typeOf val == "path");
    # A list.
    list = newPrimitive "list" (val: typeOf val == "list");
    # A list where every value is a specific type.
    listOf =
      ty:
      assert ty ? __nixty_type;
      (newPrimitive "listOf-${ty.__nixty}" (val: typeOf val == "list" && all (val: isType val ty) val))
      // {
        __functor =
          self: val:
          if typeOf val == "list" then
            map (val: ty val) val
          else
            throw "Nixty type error: ${self.__nixty_errctx val}";
      };
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
        primitive = newPrimitive "nullOr-${ty.__nixty}" (val: val == null || (isType val ty));
      in
      primitive // { __functor = self: val: if val == null then null else ty val; };
    # One of the values given in a specific list.
    oneOfVal =
      validValues:
      (newPrimitive "oneOfVal" (val: elem val validValues))
      // {
        __nixty_errctx = val: "Expected one of ${toJSON validValues}, got ${toJSON val}";
      };
    # Any value whose type is in the given list.
    oneOfTy =
      validTypes:
      assert all (ty: ty ? __nixty_type) validTypes;
      let
        len = length validTypes;
      in
      newPrimitive "oneOfTy" (val: any (ty: isType val ty) validTypes)
      // {
        __functor =
          self: val:
          let
            checkRecursive =
              idx:
              let
                test = tryEval ((elemAt validTypes idx) val);
              in
              if test.success then
                test.value
              else if (idx + 1) < len then
                checkRecursive (idx + 1)
              else
                throw "Nixty type error: ${self.__nixty_errctx val}";
          in
          checkRecursive 0;
        __nixty_errctx =
          val:
          "Expected one of the types [${
            concatStringsSep ", " (map (ty: "`${ty.__nixty}`") validTypes)
          }], got type `${type val}`";
      };
    # A Nixty type, falling back to a default value if the value isn't given.
    withDefault =
      default: ty:
      assert ty ? __nixty_type;
      assert isType default ty;
      let
        primitive = (newPrimitive "${ty.__nixty}-withDefault" (val: val == null || isType val ty));
      in
      primitive // { __functor = self: val: if val == null then default else ty val; };
    # Normally when defining a new type, Nixty checks every single field in the
    # type definition and makes sure its value is a valid Nixty type. This
    # function bypasses that check. When you use it, Nixty will not verify that
    # the provided value is a valid Nixty type - you are responsible for
    # verifying that.
    #
    # This can be useful for recursive types (e.g. Type A has a field of Type B
    # which has a field of Type A) - normally these trigger an infinite
    # recursion error, but `unsafeAssumeTy` can avoid that.
    unsafeAssumeTy =
      ty:
      (newPrimitive "unsafeAssumedType" (val: isType val ty))
      // {
        __functor = self: val: ty val;
      };
  };
}
