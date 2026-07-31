{ config, pkgs, ... }:
let
  domain = "events.${config.networking.domain}";
in
{
  sops.secrets."pretix/env".owner = "pretix";
  services.pretix = {
    enable = true;
    environmentFile = config.sops.secrets."pretix/env".path;
    plugins = [
      (pkgs.python3.pkgs.callPackage ./pkgs/oidc.nix { })
    ];

    nginx = {
      enable = true;
      domain = domain;
    };

    settings = {
      pretix = {
        instance_name = "iFSR Events";
        url = "https://${domain}";
        currency = "EUR";
        registration = false;
        auth_backends = "pretix_oidc.auth.OIDCAuthBackend";
      };
      oidc = {
        title = "iFSR Login";
        issuer = "https://idm.ifsr.de/application/o/pretix/";
        authorization_endpoint = "https://idm.ifsr.de/application/o/authorize/";
        token_endpoint = "https://idm.ifsr.de/application/o/token/";
        userinfo_endpoint = "https://idm.ifsr.de/application/o/userinfo/";
        end_session_endpoint = "https://idm.ifsr.de/application/o/pretix/end-session/";
        jwks_uri = "https://idm.ifsr.de/application/o/pretix/jwks/";
        client_id="pretix";
        scopes = "openid,email,profile,pretix";
        staff_claim="admin";
        staff_value="true";
      };

      mail = {
        from = "pretix@${config.networking.domain}";
        host = "127.0.0.1";
        port = 25;
      };
    };
  };
}
