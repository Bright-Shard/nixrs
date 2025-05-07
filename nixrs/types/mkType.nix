with builtins;

{
  typeName,
  schema,
}:

rec {
  inherit typeName;
  inherit schema;

  # Takes some input, a table with the correct fields and their types, and a
  # name for the type. Asserts that the input's fields match the correct fields,
  # then returns a table with the `type` field set.
  build =
    input:
    let
      inputFields = attrNames input;
      validateField =
        field:
        let
          input = input.${field};
          schema = schema.${field};
          schemaType = typeOf schema;
          inputType = typeOf input;
        in
        if schemaType == "lambda" then
          schema.${field} == input.${field}
        else if schemaType == "list" then
          elem inputType schema
        else
          inputType == schema;
    in

    if ((len inputFields) != (len (attrNames schema))) then
      abort "Incorrect number of arguments provided to build a ${typeName} table"
    else
      assert all validateField inputFields;
      input
      // {
        type = typeName;
      };

  isType = val: val.type == typeName;

  type = "${typeName}_meta";
}
