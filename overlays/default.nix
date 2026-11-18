_final: prev:
let
  inherit (prev) fetchurl;
in
{

  # manual patch until security release comes in stable
  apacheHttpd = prev.apacheHttpd.overrideAttrs (_: rec {
    version = "2.4.71";
    src = fetchurl {
      url = "mirror://apache/httpd/httpd-${version}.tar.bz2";
      hash = "sha256-K8XaWjPCRzQd4IJxfU68tctJ6Lc6Bbf9331dbcL43mI=";
    };
  });
  # manual patch until security release comes in stable
  nginxStable = prev.nginxStable.overrideAttrs (_: rec {
    version = "1.30.7";
    src =  fetchurl {
      url = "https://nginx.org/download/nginx-${version}.tar.gz";
      hash = "sha256-JWW1yDcFDpWPcPsPc8SOK8pFQq00n9NW9G+wxyYQvG4=";
    };
   });
}
