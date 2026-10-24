{ pkgs, config, kpp, lib, ... }:
let
  domain = "kpp.${config.networking.domain}";
  user = "kpp";
  group = "kpp";
  uid = 500;
  dataDir = "/var/lib/kpp";
  webRoot = kpp.packages.x86_64-linux.kpp;
in
{

  systemd.tmpfiles.rules = [
    "d /run/containers/kpp/ 0770 nginx nginx -"
  ];
  # create the user in both the container and the host system to keep ftp access consitently
  users.users.kpp = {
    group = group;
    isSystemUser = true;
    uid = uid;
  };
  users.groups.kpp.gid = uid;
  containers.kpp = let
    basePackages = config.environment.systemPackages;
    in

  {
    autoStart = true;
    privateUsers = "no";
    bindMounts = {
      # expose nginx via socket instead of port
      "/run/containers/kpp" = {
        hostPath = "/run/containers/kpp";
        isReadOnly = false;
      };
      # actual ftp folder
      "/srv/ftp/gedankenprotokolle" = {
        hostPath = "/srv/ftp/gedankenprotokolle";
        isReadOnly = false;
      };
    };
    config = { config, lib, kpp, pkgs, ... }: {
      system.stateVersion = "26.05";

      environment.systemPackages = basePackages;

      programs.msmtp = {
        enable = true;
        accounts.default = {
          auth = false;
          host = "localhost";
        };
      };
      
      services.phpfpm.pools.kpp = {
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
          "php_admin_value[sendmail_path]" = "/run/current-system/sw/bin/msmtp -t -i -f noreply@ifsr.de";
        };
        phpEnv."PATH" = lib.makeBinPath [ pkgs.php ];
      };

      users.users.kpp = {
        group = group;
        isSystemUser = true;
        uid = uid;
      };
      users.groups.kpp.gid = uid;
      systemd.tmpfiles.rules = [
        "d '${dataDir}' 0700 ${user} ${group} - -"
      ];
      services.nginx = {
        enable = true;
        defaultListen = [{
          addr = "unix:/run/containers/kpp/nginx.sock";
        }];

        virtualHosts.${domain} = {
          root = webRoot;
          locations = {
            "= /" = {
              extraConfig = ''
                rewrite ^ /index.php;
              '';
            };
            "~ \.php$" = {
              extraConfig = ''
                try_files $uri =404;
                fastcgi_pass unix:${config.services.phpfpm.pools.kpp.socket};
                fastcgi_index index.php;
                include ${pkgs.nginx}/conf/fastcgi_params;
                include ${pkgs.nginx}/conf/fastcgi.conf;
              '';
            };
          };
        };
      };

    };
  };
  services.nginx.virtualHosts."${domain}" = rec {
    locations = {
      "/" = {
        proxyPass = "http://unix:/run/containers/kpp/nginx.sock";
      };
      "/control" = {
        extraConfig = ''
          auth_request     /outpost.goauthentik.io/auth/nginx;
          error_page       401 = @goauthentik_proxy_signin;
          auth_request_set $auth_cookie $upstream_http_set_cookie;
          add_header       Set-Cookie $auth_cookie;

          # translate headers from the outposts back to the actual upstream
          auth_request_set $authentik_username $upstream_http_x_authentik_username;
          auth_request_set $authentik_groups $upstream_http_x_authentik_groups;
          auth_request_set $authentik_entitlements $upstream_http_x_authentik_entitlements;
          auth_request_set $authentik_email $upstream_http_x_authentik_email;
          auth_request_set $authentik_name $upstream_http_x_authentik_name;
          auth_request_set $authentik_uid $upstream_http_x_authentik_uid;

          proxy_set_header X-authentik-username $authentik_username;
          proxy_set_header X-authentik-groups $authentik_groups;
          proxy_set_header X-authentik-entitlements $authentik_entitlements;
          proxy_set_header X-authentik-email $authentik_email;
          proxy_set_header X-authentik-name $authentik_name;
          proxy_set_header X-authentik-uid $authentik_uid;
        '';
      };

      "/outpost.goauthentik.io".extraConfig = ''
        proxy_pass              http://idm.ifsr.de:9000/outpost.goauthentik.io;

        # Note: ensure the Host header matches your external authentik URL:
        proxy_set_header        Host $host;

        proxy_set_header        X-Original-URL $scheme://$http_host$request_uri;
        add_header              Set-Cookie $auth_cookie;
        auth_request_set        $auth_cookie $upstream_http_set_cookie;
        proxy_pass_request_body off;
        proxy_set_header        Content-Length "";
      '';
      "@goauthentik_proxy_signin".extraConfig = ''
        internal;
        add_header Set-Cookie $auth_cookie;
        return 302 /outpost.goauthentik.io/start?rd=$scheme://$http_host$request_uri;
        # For domain level, use the below error_page to redirect to your authentik server with the full redirect path
        # return 302 https://authentik.company/outpost.goauthentik.io/start?rd=$scheme://$http_host$request_uri;
      '';
    };
  };
}
