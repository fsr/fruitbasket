_final: prev:
let
  inherit (prev) fetchurl;
  inherit (prev) fetchpatch;
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
  portunus = callPackage ./portunus.nix { };
  mediawiki = (prev.mediawiki.overrideAttrs (_old: rec {
    version = "1.43.0";

    src = fetchurl {
      url = "https://releases.wikimedia.org/mediawiki/${prev.lib.versions.majorMinor version}/mediawiki-${version}.tar.gz";
      hash = "sha256-VuCn/i/3jlC5yHs9WJ8tjfW8qwAY5FSypKI5yFhr2O4=";
    };

  }));

  hedgedoc = prev.hedgedoc.overrideAttrs ({ patches ? [ ], ... }: {
    patches = patches ++ [
      ./hedgedoc/0001-anonymous-uploads.patch
    ];
  });
  # patch to remove the nixspam blocklist. Remove after next rspamd release
  rspamd = prev.rspamd.overrideAttrs ({ patches ? [ ], ... }: {
    patches = patches ++ [
      (fetchpatch {
        url = "https://patch-diff.githubusercontent.com/raw/rspamd/rspamd/pull/5300.diff";
        hash = "sha256-7zY+l5ADLWgPTTBNG/GxX23uX2OwQ33hyzSuokTLgqc=";
      })
    ];
  });

}
