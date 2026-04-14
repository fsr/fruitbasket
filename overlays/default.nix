_final: prev:
let
  inherit (prev) libpq;
  inherit (prev) lib;
in
{
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
