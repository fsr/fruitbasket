{ config, pkgs, lib, ... }:
let
  domain = "fsrewsp.${config.fsr.domain}";
in
{
  services = {
    services.wordpress.sites."${domain}" = {
        languages = [ pkgs.wordpressPackages.languages.de_DE ];
        settings = {
            WPLANG = "de_DE";
            FORCE_SSL_ADMIN = true;
        };
        virtualHost.enableACME = true;
        extraConfig = ''
            $_SERVER['HTTPS']='on';
        '';
    };
  };
}
