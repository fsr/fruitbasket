{ pkgs, config, lib, ... }:
let
  domain = "fsrewsp.staging.ifsr.de";
in
{
  services.wordpress = {
    webserver = "nginx";
    sites.${domain} = {
      languages = [ pkgs.wordpressPackages.languages.de_DE ];
      settings = {
        WPLANG = "de_DE";
      };
      database = {
        name = "wordpress_fsrewsp";
      };
    };
  };
  services.nginx.virtualHosts."${domain}" = {
    enableACME = true;
    forceSSL = true;
  };
}
