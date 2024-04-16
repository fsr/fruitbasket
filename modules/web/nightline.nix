{ pkgs, config, lib, ... }:
let
  domain = "nightline-dresden.de";
  user = "nightline";
  group = "nightline";
in
{
  users.users.${user} = {
    group = group;
    isSystemUser = true;
  };
  users.users.nginx = {
    extraGroups = [ group ];
  };
  users.groups.${group} = { };

  services.phpfpm.pools.nightline = {
    user = "nightline";
    group = "nightline";
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
    virtualHosts."www.${domain}" = {
      locations."/".return = "301 $scheme://${domain}$request_uri";
    };
    virtualHosts."${domain}" = {
      root = "/srv/web/nightline";
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
            fastcgi_pass unix:${config.services.phpfpm.pools.nightline.socket};
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
