{ config, lib, pkgs, ... }:
let
  domain = "vernetzung.${config.networking.domain}";
  user = "vernetzung";
  group = "vernetzung";
in
{

  users.users.${user} = {
    group = group;
    isSystemUser = true;
  };
  users.groups.${group} = { };
  services.phpfpm.pools.vernetzung = {
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
    virtualHosts."${domain}" = {
      root = "/srv/web/vernetzung";
      extraConfig = ''
        index index.php;
      '';
      locations = {
        "/" = {
          tryFiles = "$uri $uri/ @rewrite";
        };
        "@rewrite".extraConfig = ''
          rewrite ^/(.*)$ /index.php?title=$1&$args;
        '';
        "^~ /maintenance/".return = "403";
        "~ \.php$" = {
          extraConfig = ''
            fastcgi_pass unix:${config.services.phpfpm.pools.vernetzung.socket};
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_index index.php;
            include ${pkgs.nginx}/conf/fastcgi_params;
            include ${pkgs.nginx}/conf/fastcgi.conf;
            fastcgi_param SCRIPT_FILENAME $document_root/$fastcgi_script_name;
          '';
        };
        "/rest.php" = {
          tryFiles = "$uri $uri/ /rest.php?$args";
        };
        "~* \.(js|css|png|jpg|jpeg|gif|ico)$" = {
          tryFiles = "$uri /index.php";
          extraConfig = ''
            expires max;
            log_not_found off;
          '';
        };
        "/_.gif" = {
          extraConfig = ''
            expires max;
            empty_gif;
          '';
        };
        "^~ /cache/".extraConfig = ''
          deny all;
        '';
        "/dumps" = {
          root = "/srv/web/vernetzung/local";
          extraConfig = ''
            autoindex on;
          '';
        };
      };
    };
  };
}
