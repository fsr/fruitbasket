{ pkgs, config, lib, ... }:
let
  domain = "sharepic.${config.networking.domain}";
  user = "sharepic";
  group = "sharepic";
in
{
  users.users.${user} = {
    group = group;
    isSystemUser = true;
  };
  users.groups.${group} = { };

  services.phpfpm.pools.sharepic = {
    user = "sharepic";
    group = "sharepic";
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
    enable = true;

    virtualHosts."${domain}" = {
      root = "/srv/web/sharepic";
      extraConfig = ''
        index index.php index.html;
        allow 141.30.0.0/16;
        allow 141.76.0.0/16;
        deny all;
      '';

      locations = {
        "/" = {
          tryFiles = "$uri $uri/ =404";
        };
        "~ \.php$" = {
          extraConfig = ''
            try_files $uri =404;
            fastcgi_pass unix:${config.services.phpfpm.pools.sharepic.socket};
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_index index.php;
            include ${pkgs.nginx}/conf/fastcgi_params;
            include ${pkgs.nginx}/conf/fastcgi.conf;
            fastcgi_param SCRIPT_FILENAME $document_root/$fastcgi_script_name;
          '';
        };
        "/data".return = "403";
      };
    };
  };
}
