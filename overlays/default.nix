_final: prev:
let
  inherit (prev) fetchurl;
  inherit (prev) libpq;
  inherit (prev) lib;
in
{
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
  sope = (prev.sope.overrideAttrs (old: {
    patches = [
      ./sope/0001-NGHashMap-keep-root-last-consistent-to-fix-segfault-.patch
    ];
    postInstall = old.postInstall + ''
      patchelf $out/lib/GNUstep/GDLAdaptors-*/PostgreSQL.gdladaptor/PostgreSQL \
        --add-needed libpq.so \
        --add-rpath ${lib.makeLibraryPath [ libpq ]}
    '';
  }));
}
