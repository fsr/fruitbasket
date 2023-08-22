{ stdenvNoCC, ... }:
stdenvNoCC.mkDerivation {
  name = "padlister";
  src = ./.;
  phases = [ "unpackPhase" "installPhase" ];
  installPhase = ''
    mkdir -p $out
    cp -r $src/index.php $out
  '';
}
