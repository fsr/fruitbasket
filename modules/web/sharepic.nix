{ pkgs, config, ... }:
let
  domain = "sharepic.${config.networking.domain}";
in
{
  services.nginx.virtualHosts."${domain}" = {
    root = pkgs.fetchFromGitHub {
      owner = "jannikmenzel";
      repo = "iFSR-Sharepicgenerator";
      rev = "ac721d5fff2dba1f046939a6d6532b1a8cfceba8";
      hash = "sha256-of+N58TDt2BcbDVEriKn6rjQVl0GdV4ZMEblrdUutZk=";
    };
    locations = {
      "/".extraConfig = ''
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
