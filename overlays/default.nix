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
  php82 = prev.php82.overrideAttrs {
    version = "8.2.36";
    hash = "sha256-9DBrStpgJjfvNd8uD0qgWdVZlSvIeSbtdG+tKwp3e3I=";
  };
  php83 = prev.php83.overrideAttrs {
    version = "8.3.37";
    hash = "sha256-eDe0PNThjbXerCHubwCGbkd5pwXy5U+uqDyKbPVv0dg=";
  };
  php84 = prev.php84.overrideAttrs {
    version = "8.4.28";
    hash = "sha256-sjqhvlt0YprWJP0BNlwOTfbYh4RzmD8zc0lDPvNJwfc=";
  };
  php85 = prev.php85.overrideAttrs {
    version = "8.5.13";
    hash = "sha256-R9UMNgFnhKSnHwGc17+inDHkvg3iLT+gYJWygKYpni8=";
  };
}
