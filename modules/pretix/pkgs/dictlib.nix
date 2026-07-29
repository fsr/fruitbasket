# obscure dependency of pretix-oidc
{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
}:

buildPythonPackage rec {
  pname = "dictlib";
  version = "1.1.5";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-auwLPx63Qkl8FKGB9nOpdqCYHmchDulVs+QXpOfTwi8=";
  };

  build-system = [
    setuptools
  ];

 doCheck = false; # no tests
}
