# Downloads a file. This function differs from nixpkgs.fetchurl because `hash`
# is the hash of the file, not the derivation, which makes it a little easier
# to work with for downloading toolchain components and crates. In both of
# those situations, the SHA-256 hash of the file is given to us in advance.

{
  currentSystem,
  pkgs,
  placeholder,
  nixty,
  ...
}:

let
  argsTy =
    with nixty.prelude;
    newType {
      name = "download-args";
      def = {
        # File to download
        url = str;
        # sha-256 hash of the downloaded file
        hash = str;
        # Derivation name, `-download` will be appended
        name = str;
      };
    };
in

rawArgs:
let
  args = argsTy rawArgs;
in

derivation {
  name = "${args.name}-download";
  system = currentSystem;
  builder = "${pkgs.curl}/bin/curl";
  args = [
    "-o"
    (placeholder "out")
    args.url
  ];
  outputHashMode = "flat";
  outputHashAlgo = "sha256";
  outputHash = args.hash;
}
