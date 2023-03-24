{ config, pkgs, ... }:
let
  domain = "ftp.rfive.de";
in
{
  services.nginx.virtualHosts."${domain}" = {
    enableACME = true;
    forceSSL = true;
    root = "/srv/ftp";
    extraConfig = ''
      autoindex on;
    '';
    locations."~/(klausuren|uebungen|skripte|abschlussarbeiten)".extraConfig = ''
      allow 141.30.0.0/16;
      allow 141.76.0.0/16;
      allow 172.16.0.0/16;
      deny all;
    '';

  };
}
