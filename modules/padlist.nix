# php pad lister tool written by jonas
{ pkgs, config, lib, ... }:
let
  domain = "list.pad.${config.networking.domain}";
in
{
  services.phpfpm.pools.padlist = {
    user = "hedgedoc";
    group = "hedgedoc";
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
    virtualHosts.${domain} = {
      root = "/srv/web/padlist";
      locations = {
        "= /" = {
          extraConfig = ''
            rewrite ^ /index.php;
          '';
        };
        "~ \.php$" = {
          extraConfig = ''
            try_files $uri =404;
            fastcgi_pass unix:${config.services.phpfpm.pools.padlist.socket};
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_index index.php;
            include ${pkgs.nginx}/conf/fastcgi_params;
            include ${pkgs.nginx}/conf/fastcgi.conf;
            fastcgi_param SCRIPT_FILENAME $document_root/$fastcgi_script_name;
          '';
        };
        "/vendor".return = "403";
      };
    };
  };
}
