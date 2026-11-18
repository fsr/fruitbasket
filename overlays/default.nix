_final: prev:
let
  inherit (prev) fetchurl;
in
{
  # manual patch until security release comes in stable
  nginxStable = prev.nginxStable.overrideAttrs (_: rec {
    version = "1.30.7";
    src =  fetchurl {
      url = "https://nginx.org/download/nginx-${version}.tar.gz";
      hash = "sha256-JWW1yDcFDpWPcPsPc8SOK8pFQq00n9NW9G+wxyYQvG4=";
    };
   });
}
