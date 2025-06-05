# My solution to dynamic typing. Types are attribute sets with specific fields,
# plus a `type` field that stores the name of the type. Each type has an
# associated builder that will create the table if all of the correct fields are
# present.

{
  attrNames,
  typeOf,
  elem,
  length,
  deepSeq,
  addErrorContext,
  ...
}:

{
  typeName,
  schema,
  addFields ? self: { },
}:

let
  type = rec {
    inherit typeName;
    inherit schema;

    # Takes some input, a table with the correct fields and their types, and a
    # name for the type. Asserts that the input's fields match the correct
    # fields, then returns a table with the `type` field set.
    build =
      input:
      let
        inputFields = attrNames input;
        fieldIsValid =
          field:
          let
            inputField = input.${field};
            schemaField = schema.${field};
            schemaType = typeOf schemaField;
            inputType = typeOf inputField;
          in
          if schemaType == "lambda" then
            schemaField inputField
          else if schemaType == "list" then
            elem inputType schemaField
          else
            inputType == schemaField;
        validate =
          field: if !(fieldIsValid field) then abort "mkType: Field `${field}` had the wrong type" else null;
      in

      addErrorContext "While building type `${typeName}`" (
        if ((length inputFields) != (length (attrNames schema))) then
          abort "Incorrect number of arguments provided to build a ${typeName} table"
        else
          deepSeq (map validate inputFields) input
          // {
            type = typeName;
          }
      );

    isType = val: val.type == typeName;

    type = "${typeName}_meta";
  };
in
type // (addFields type)
