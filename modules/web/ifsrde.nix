{ config, pkgs, lib, ... }:
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
        "/mese".return = "301 https://ifsr.de/news/mese-and-welcome-back";
        "/sso".return = "301 https://sso.ifsr.de/realms/internal/account";
        # security
        "~* /(\.git|cache|bin|logs|backup|tests)/.*$".return = "403";
        # deny running scripts inside core system folders
        "~* /(system|vendor)/.*\.(txt|xml|md|html|json|yaml|yml|php|pl|py|cgi|twig|sh|bat)$".return = "403";
        # deny running scripts inside user folder
        "~* /user/.*\.(txt|md|json|yaml|yml|php|pl|py|cgi|twig|sh|bat)$".return = "403";
        # deny access to specific files in the root folder
        "~ /(LICENSE\.txt|composer\.lock|composer\.json|nginx\.conf|web\.config|htaccess\.txt|\.htaccess)".return = "403";
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
