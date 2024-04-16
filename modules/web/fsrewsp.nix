{ pkgs, config, lib, ... }:
let
  domain = "fsrewsp.de";
  user = "fsrewsp";
  group = "fsrewsp";
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

  services.phpfpm.pools.fsrewsp = {
    user = "fsrewsp";
    group = "fsrewsp";
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



  services.nginx.enable = true;
  services.nginx = {
    virtualHosts."www.${domain}" = {
      locations."/".return = "301 $scheme://${domain}$request_uri";
    };
    virtualHosts."${domain}" = {
      root = "/srv/web/fsrewsp";
      extraConfig = ''
        index index.php index.html;
      '';

      locations = {
        "/" = {
          tryFiles = "$uri $uri/ /index.php?$args";
        };
        "~ \.php$" = {
          extraConfig = ''
            try_files $uri =404;
            fastcgi_pass unix:${config.services.phpfpm.pools.fsrewsp.socket};
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_index index.php;
            include ${pkgs.nginx}/conf/fastcgi_params;
            include ${pkgs.nginx}/conf/fastcgi.conf;
            fastcgi_param SCRIPT_FILENAME $document_root/$fastcgi_script_name;
            fastcgi_param HTTP_HOST $host;
          '';
        };
        "~ \.log$".return = "403";
        "~ ^/\.user\.ini".return = "403";
        "~* \.(js|css|png|jpg|jpeg|gif|ico)$".extraConfig = ''
          expires max;
          log_not_found off;
        '';
      };
    };
  };
}
