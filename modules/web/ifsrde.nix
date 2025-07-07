{ config, pkgs, ... }:
let
  user = "fsr-web";
  group = "fsr-web";
  webRoot = "/srv/web/ifsrdenew";
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

    virtualHosts."${config.networking.domain}" = {
      root = webRoot;
      locations = {
        "/" = {
          tryFiles = "$uri $uri/ =404";
        };
        "~ ^/cmd(/?[^\\n|\\r]*)$".return = "301 https://pad.ifsr.de$1";
        "/bbb".return = "301 https://bbb.tu-dresden.de/b/fsr-58o-tmf-yy6";
        "/kpp".return = "301 https://kpp.ifsr.de";
        # important redirects from the old website
        "/service/altklausuren".return = "301 https://ifsr.de/studium/stoffkiste-und-ftp";
        "/service/komplexpruefungen".return = "301 https://ifsr.de/studium/stoffkiste-und-ftp";
        "~ ^/fachschaftsrat(/?[^\\n|\\r]*)$".return = "301 https://ifsr.de/about/$1";
        "~ ^/service(/?[^\\n|\\r]*)$".return = "301 https://ifsr.de/services/$1";
        "/sitzung".return = "301 https://ifsr.de/sitzung-und-protokolle/";
        # security
        ## End - Security
      };
    };
  };

  users.users."ese-deploy" = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      ''command="${pkgs.rrsync}/bin/rrsync ${webRoot}",restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFRIojP9vBbxy0fCEJFMNKXgkTA7Sju9mn+i01mYzovU''
    ];
  };
}
