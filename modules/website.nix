{ config, pkgs, lib, ... }:
let
  www-domain = "www.${config.fsr.domain}";
  user = "fsr-web";
  group = "fsr-web";
in
{

  users.users.${user} = {
    group = group;
    isSystemUser = true;
  };
  users.groups.${group} = { };

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

  services.nginx = rec {
    virtualHosts.${www-domain} = {
      root = "/srv/web/ifsrde";
      locations = {
        "= /" = {
          extraConfig = ''
            rewrite ^ /index.php;
          '';
        };
        "~ \.php$" = {
          extraConfig = ''
            try_files $uri =404;
            fastcgi_pass unix:${config.services.phpfpm.pools.ifsrde.socket};
            fastcgi_index index.php;
            include ${pkgs.nginx}/conf/fastcgi_params;
            include ${pkgs.nginx}/conf/fastcgi.conf;
          '';
        };
      };
    };
    # ifsr.de without www
    virtualHosts.${config.fsr.domain} = virtualHosts.${www-domain};
  };
}
