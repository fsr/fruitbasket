{ pkgs, config, lib, ... }:
let
  domain = "sharepic.${config.networking.domain}";
in
{
  services.nginx.virtualHosts."${domain}" = {
    root = pkgs.fetchFromGitHub {
      owner = "jannikmenzel";
      repo = "iFSR-Sharepicgenerator";
      rev = "ac721d5fff2dba1f046939a6d6532b1a8cfceba8";
      hash = "sha256-of+N58TDt2BcbDVEriKn6rjQVl0GdV4ZMEblrdUutZk=";
    };
  };
}
