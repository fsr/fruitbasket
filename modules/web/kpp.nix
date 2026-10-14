{ pkgs, config, ... }:
let
  domain = "kpp.${config.networking.domain}";
in
{
  services.kpp = {
    enable = true;
    hostName = domain;
  };
  services.nginx.virtualHosts."${domain}" = rec {
    # ugly hack to put the sensitive endpoints behind authentication\
    # we need to rewrite the control section anyways
    locations = {
        "= /control/accept.php" = {
          extraConfig = ''
            try_files $uri =404;
            fastcgi_pass unix:${config.services.phpfpm.pools.kpp.socket};
            fastcgi_index index.php;
            include ${pkgs.nginx}/conf/fastcgi_params;
            include ${pkgs.nginx}/conf/fastcgi.conf;

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
        "= /control/decline.php" = locations."= /control/accept.php";
      
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
