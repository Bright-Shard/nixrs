# Downloads a file. This function differs from nixpkgs.fetchurl because `hash`
# is the hash of the file, not the derivation, which makes it a little easier
# to work with for downloading toolchain components and crates. In both of
# those situations, the SHA-256 hash of the file is given to us in advance.

{
  currentSystem,
  pkgs,
  placeholder,
  ...
}:

{
  # File to download
  url,
  # sha-256 hash of the downloaded file
  hash,
  # Derivation name, `-download` will be appended
  name,
}:

derivation {
  name = "${name}-download";
  system = currentSystem;
  builder = "${pkgs.curl}/bin/curl";
  args = [
    "-o"
    (placeholder "out")
    url
  ];
  outputHashMode = "flat";
  outputHashAlgo = "sha256";
  outputHash = hash;
}
