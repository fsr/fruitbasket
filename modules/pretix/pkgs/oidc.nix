# Package definition for pretix-oidc

{
  lib,
  callPackage,
  buildPythonPackage,
  fetchPypi,
  replaceVars,

  # build-system
  setuptools,

  # runtime
  openssl,

  # dependencies
  oic
}:

buildPythonPackage rec {
  pname = "pretix_oidc";
  version = "2.3.1";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-uTx3vz+1o3LhJzzWEi5cOSNADw4G8CQDMVN/sadP6kk=";
  };

  build-system = [
    (callPackage ./plugin-build.nix { })
    setuptools
  ];

  dependencies = [
    oic
    (callPackage ./dictlib.nix { })
  ];

  doCheck = false; # no tests

  meta = {
    description = "OIDC authentication plugin for pretix";
    homepage = "https://github.com/pretix/pretix-oidc";
    license = lib.licenses.mit;
  };
}
