{ isPy3k, buildPythonPackage, pkgs, service-identity, ldap3, twisted, ldaptor, mock }:

buildPythonPackage rec {
  pname = "matrix-synapse-ldap3";
  version = "0.2.2";

  format = "pyproject";

  src = pkgs.fetchFromGitHub {
    owner = "matrix-org";
    repo = "matrix-synapse-ldap3";
    rev = "2584736204165f16c176567183f9c350ee253f74";
    sha256 = "gMsC5FpC2zt5hypPdGgPbWT/Rwz38EoQz3tj5dQ9BQ8=";
  };

  propagatedBuildInputs = [ service-identity ldap3 twisted ];

  # ldaptor is not ready for py3 yet
  doCheck = !isPy3k;
  checkInputs = [ ldaptor mock ];
}
