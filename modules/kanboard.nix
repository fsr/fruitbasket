{ pkgs, config, lib, ... }:
let
  user = "kanboard";
  group = "kanboard";
in
{
  users.users.${user} = {
    group = group;
    isSystemUser = true;
  };
  users.groups.${group} = { };

  services.phpfpm.pools.kanboard = {
    user = "kanboard";
    group = "kanboard";
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
  services.nginx.virtualHosts."kanboard.staging.ifsr.de" = {
    addSSL = true;
    enableACME = true;
    root = "/srv/web/kanboard";
    extraConfig = ''
      index index.html index.php;
    '';

    locations = {
      "/" = {
        tryFiles = "$uri $uri/ =404";
      };
      "~ \.php$" = {
        extraConfig = ''
          try_files $uri =404;
          fastcgi_pass unix:${config.services.phpfpm.pools.kanboard.socket};
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
}
