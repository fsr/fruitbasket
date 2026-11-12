_final: prev:
let
  inherit (prev) fetchurl;
in
{

  apacheHttpd = prev.apacheHttpd.overrideAttrs (_: rec {
    version = "2.4.71";

    src = fetchurl {
      url = "mirror://apache/httpd/httpd-${version}.tar.bz2";
      hash = "sha256-K8XaWjPCRzQd4IJxfU68tctJ6Lc6Bbf9331dbcL43mI=";
    };
  });
}
