{
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  name = "nixrs";
  src = ./.;
  preInstall = ''
    mkdir $out
    mv bin $out/bin
    mv misc $out
    mv nixrs $out
  '';
}
