{ config, pkgs, ... }:
let
  user = "fsr-web";
  group = "fsr-web";
  webRoot = "/srv/web/ifsr.de";
in
{
  users.users.${user} = {
    group = group;
    isSystemUser = true;
  };
  users.groups.${group} = { };
  users.users.nginx = {
    extraGroups = [ group ];
  };
  services.nginx = {

    virtualHosts."www.${config.networking.domain}" = {
      locations."/".return = "301 $scheme://ifsr.de$request_uri";
    };
    virtualHosts."${config.networking.domain}" = {
      root = webRoot;
      locations = {
        "/" = {
          tryFiles = "$uri $uri/ =404";
          extraConfig = ''
            error_page 404 /404.html;
          '';
        };
        "~ ^/cmd(/?[^\\n|\\r]*)$".return = "301 https://pad.ifsr.de$1";
        "/bbb".return = "301 https://bbb.tu-dresden.de/b/fsr-58o-tmf-yy6";
        "/kpp".return = "301 https://kpp.ifsr.de";
        # important redirects from the old website
        "~ /studium/stoffkiste/?$".return = "301 https://ifsr.de/studium/stoffkiste-und-ftp";
        "~ /service/notenrechner/?$".return = "301 https://notenrechner.ifsr.de";
        "/service/altklausuren".return = "301 https://ifsr.de/studium/stoffkiste-und-ftp";
        "/service/komplexpruefungen".return = "301 https://ifsr.de/studium/stoffkiste-und-ftp";
        "~ ^/fachschaftsrat(/?[^\\n|\\r]*)$".return = "301 https://ifsr.de/about$1";
        "~ ^/service/?[^\\n|\\r]*$".return = "301 https://ifsr.de/studium/services";
        "~ /sitzung/?$".return = "301 https://ifsr.de/sitzung-und-protokolle/";
      };
    };
  };

  users.users."ifsrde-deploy" = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      ''command="${pkgs.rrsync}/bin/rrsync ${webRoot}",restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFRIojP9vBbxy0fCEJFMNKXgkTA7Sju9mn+i01mYzovU''
    ];
  };
}
