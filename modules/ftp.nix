{ config, pkgs, ... }:
let
  domain = "ftp.ifsr.de";
in
{
  services.nginx.additionalModules = [pkgs.nginxModules.fancyindex];
  services.nginx.virtualHosts."${domain}" = {
    enableACME = true;
    forceSSL = true;
    root = "/srv/ftp";
    extraConfig = ''
      fancyindex on;
      fancyindex_exact_size off;
    '';
    locations."~/(klausuren|uebungen|skripte|abschlussarbeiten)".extraConfig = ''
      allow 141.30.0.0/16;
      allow 141.76.0.0/16;
      allow 172.16.0.0/16;
      deny all;
    '';

  };
}
