_final: prev:
let
  inherit (prev) callPackage;
  inherit (prev) fetchpatch;
in
{

  apacheHttpd = prev.apacheHttpd.overrideAttrs (_: {
    version = "2.4.71";

  src = fetchurl {
    url = "mirror://apache/httpd/httpd-${version}.tar.bz2";
    hash = "";
  };
  });
}
