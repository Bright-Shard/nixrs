# A rust-analyzer crate: https://rust-analyzer.github.io/book/non_cargo_based_projects.html

{
  nixty,
  VALID_RUST_EDITIONS_STR,
  ...
}:

with nixty.prelude;

newType {
  name = "rustAnalyzerCrate";
  def = {
    # TODO: There are more options I'm not adding here because I'm just adding
    # enough to get most crates to build
    root_module = str;
    edition = oneOfVal VALID_RUST_EDITIONS_STR;
    deps = list;
    is_workspace_member = bool;
    cfg = list;
    env = set;
    is_proc_macro = bool;
  };
}
