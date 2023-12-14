_final: prev:
let
  inherit (prev) fetchurl;
in
{
  # AGDSN is running an outdated version that we have to comply to
  bacula = (prev.bacula.overrideAttrs (old: rec {
    version = "9.6.7";
    src = fetchurl {
      url = "mirror://sourceforge/bacula/${old.pname}-${version}.tar.gz";
      sha256 = "sha256-3w+FJezbo4DnS1N8pxrfO3WWWT8CGJtZqw6//IXMyN4=";
    };
  }));

}
