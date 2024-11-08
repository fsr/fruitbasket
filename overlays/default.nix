_final: prev:
let
  inherit (prev) fetchurl;
  inherit (prev) callPackage;
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
  # Mailman internal server error fix
  # https://gitlab.com/mailman/mailman/-/issues/1137
  # https://github.com/NixOS/nixpkgs/pull/321136
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (_python-final: python-prev: {
      readme-renderer = python-prev.readme-renderer.overridePythonAttrs (_oldAttrs: {
        propagatedBuildInputs = [ python-prev.cmarkgfm ];
      });
    })
  ];

  keycloak_ifsr_theme = callPackage ../modules/keycloak/theme.nix { };
}
