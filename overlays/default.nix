_final: prev:
let
  inherit (prev) fetchurl;
  inherit (prev) fetchFromGitHub;
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
  # (hopefully) fix systemd journal reading
  prometheus-postfix-exporter = prev.prometheus-postfix-exporter.overrideAttrs (_old: {
    patches = [
      ./prometheus-postfix-exporter/0001-cleanup-also-catch-milter-reject.patch
    ];
    src = fetchFromGitHub {
      owner = "adangel";
      repo = "postfix_exporter";
      rev = "414ac12ee63415eede46cb3084d755a6da6fba23";
      hash = "sha256-m1kVaO3N7XC1vtnxXX9kMiEFPmZuoopRUYgA7gQzP8w=";
    };
  });

}
