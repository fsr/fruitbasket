{ stdenv }:
stdenv.mkDerivation rec {
  name = "keycloak_ifsr_theme";
  version = "1.1";

  src = ./theme;

  nativeBuildInputs = [ ];
  buildInputs = [ ];

  installPhase = ''
    mkdir -p $out
    cp -a login $out
  '';
}
