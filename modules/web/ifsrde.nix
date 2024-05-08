{ config, pkgs, lib, ... }:
let
  user = "fsr-web";
  group = "fsr-web";
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
  services.phpfpm.pools.ifsrde = {
    user = user;
    group = group;
    settings = {
      "listen.owner" = config.services.nginx.user;
      "pm" = "dynamic";
      "pm.max_children" = 32;
      "pm.max_requests" = 500;
      "pm.start_servers" = 2;
      "pm.min_spare_servers" = 2;
      "pm.max_spare_servers" = 5;
      "php_admin_value[error_log]" = "stderr";
      "php_admin_flag[log_errors]" = true;
      "catch_workers_output" = true;
    };
    phpEnv."PATH" = lib.makeBinPath [ pkgs.php ];
  };

  services.nginx = {

    virtualHosts."www.${config.networking.domain}" = {
      locations."/".return = "301 $scheme://ifsr.de$request_uri";
    };
    virtualHosts."${config.networking.domain}" = {
      root = "/srv/web/ifsrde";
      extraConfig = ''
        index index.html index.php;
      '';

      locations = {
        "/" = {
          tryFiles = "$uri $uri/ /index.php?$query_string";
        };
        "~ \.php$" = {
          extraConfig = ''
            try_files $uri =404;
            fastcgi_pass unix:${config.services.phpfpm.pools.ifsrde.socket};
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_index index.php;
            include ${pkgs.nginx}/conf/fastcgi_params;
            include ${pkgs.nginx}/conf/fastcgi.conf;
            fastcgi_param SCRIPT_FILENAME $document_root/$fastcgi_script_name;
          '';
        };
        "~ ^/cmd(/?[^\\n|\\r]*)$".return = "301 https://pad.ifsr.de$1";
        "/bbb".return = "301 https://bbb.tu-dresden.de/b/fsr-58o-tmf-yy6";
        "/kpp".return = "301 https://kpp.ifsr.de";
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
}
