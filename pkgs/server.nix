{ lib
,pkgs
#, buildpythonApplication
#, buildPythonPackage
, fetchFromGitHub 
#, fetchPypi
}:
let

dvb = pkgs.python39Packages.buildPythonPackage rec {
  pname = "dvb";
  version = "1.2.0";

  src = fetchFromGitHub {
    owner = "revol-xut";
    repo = "dvbpy";
    rev = "66c975f58b9f831ff6044aa65da58c3246938e5e";
    sha256 = "sha256-OzK9r6tyyjawdDzqrDw9CFh0lf8Bn11rJpQl60YCoT8=";
  };

  doCheck = false;
  propagatedBuildInputs = with pkgs.python39Packages; [ pyproj numpy requests ];
};

flask-misaka = pkgs.python39Packages.buildPythonPackage rec {
  pname = "flask-misaka";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "singingwolfboy";
    repo = "flask-misaka";
    rev = "d960e512ac1ea16225d236984fcf130a46bb7b83";
    sha256 = "sha256-RYDD+Bj3+S2isTdccl04zvLjpbalQ5sqb3sYnUy1+bU=";
  };

  doCheck = false;
  propagatedBuildInputs = with pkgs.python39Packages; [ flask misaka ];
};



in pkgs.python39Packages.buildPythonApplication rec {
  pname = "fsr-infoscreen";
  version = "2.1.0";

  src = fetchFromGitHub{
    owner = "fsr";
    repo = "infoscreen";
    rev = "43fb1fdc9dd15ccf40ef28b448ac6cfd51f32bc4";
    sha256 = "sha256-KVIuL9g5gYC+3o2U7HQRqHQnU02kn7E9P7ZydFc/tyA=";
  };
  nativeBuildInputs = with pkgs; [ pkg-config python3Packages.wrapPython ];
  propagatedBuildInputs = with pkgs.python39Packages; [ flask python-forecastio flask-misaka dvb ];
  buildInputs = with pkgs.python39Packages; [ flask python-forecastio flask-misaka dvb ];
  pythonPath = with pkgs.python39Packages; [ flask python-forecastio flask-misaka dvb];
  
  installPhase = ''
    mkdir -p $out/build/middleware
    install -Dm755 middleware/infoscreen.py $out/build/middleware
    mkdir -p $out/share/infoscreen
    wrapPythonPrograms
  '';

  makeWrapperArgs = [
    "--prefix PYTHONPATH : $out/share/fsr-infoscreen"
  ];

  meta = with lib; {
    description = "A minimal python server which supplies the fsr infoscreen with information.";
    homepage = "https://github.com/fsr/infoscreen";
    license = licenses.mit;
    maintainers = with maintainers; [ revol-xut ];
  };
}
