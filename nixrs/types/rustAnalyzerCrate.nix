# A rust-analyzer crate: https://rust-analyzer.github.io/book/non_cargo_based_projects.html

{
  mkType,
  elem,
  VALID_RUST_EDITIONS_STR,
  ...
}:

mkType {
  typeName = "rustAnalyzerCrate";
  schema = {
    # TODO: There are more options I'm not adding here because I'm just adding
    # enough to get most crates to build
    root_module = "string";
    edition = val: elem val VALID_RUST_EDITIONS_STR;
    deps = "list";
    is_workspace_member = "bool";
    cfg = "list";
    env = "set";
    is_proc_macro = "bool";
  };
}
