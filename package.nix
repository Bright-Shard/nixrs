{
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  name = "nixrs";
  src = ./.;
  preInstall = ''
    mkdir $out
    mv bin $out/bin
    mv cli.nix $out
    mv nixrs $out
  '';
}
