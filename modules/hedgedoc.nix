{ config, pkgs, lib, ... }:
let
  domain = "pad.${config.networking.domain}";
  template = pkgs.writeText "hedgedoc-template.md" ''
    ---
    tags: listed
    ---
  '';
in
{
  services = {
    postgresql = {
      enable = true;
      ensureUsers = [
        {
          name = "hedgedoc";
          ensureDBOwnership = true;
        }
      ];
      ensureDatabases = [ "hedgedoc" ];
    };

    hedgedoc = {
      enable = true;
      settings = {
        allowFreeURL = true;
        port = 3002;
        domain = "${domain}";
        protocolUseSSL = true;
        db = {
          dialect = "postgres";
          host = "/run/postgresql/";
        };
        sessionSecret = "\${SESSION_SECRET}";
        csp = {
          enable = true;
          directives = {
            scriptSrc = "${domain}";
          };
          upgradeInsecureRequest = "auto";
          addDefaults = true;
        };
        allowGravatar = false;

        ## authentication
        # disable email
        email = false;
        allowEmailRegister = false;
        # allow anonymous editing, but not creation of pads
        allowAnonymous = false;
        allowAnonymousEdits = true;
        allowAnonymousUploads = false;
        defaultPermission = "limited";
        defaultNotePath = builtins.toString template;
        oauth2 = {
          providerName = "iFSR";
          authorizationURL = "https://idm.ifsr.de/application/o/authorize/";
          tokenURL = "https://idm.ifsr.de/application/o/token/";
          userProfileURL = "https://idm.ifsr.de/application/o/userinfo/";
          clientID = "hedgedoc";
          clientSecret = "\${OIDC_SECRET}";
          scope = [ "openid" "email" "profile" ];
          userProfileUsernameAttr= "preferred_username";
          userProfileDisplayNameAttr= "name";
          userProfileEmailAttr= "email";
        };
      };
    };

    nginx = {
      recommendedProxySettings = true;
      virtualHosts = {
        "${domain}" = {
          locations."/" = {
            proxyPass = "http://[::1]:${toString config.services.hedgedoc.settings.port}";
            proxyWebsockets = true;
          };
          locations."/robots.txt" = {
            extraConfig = ''
              add_header  Content-Type  text/plain;
              return 200 "User-agent: *\nDisallow: /\n";
            '';
          };
        };
      };
    };
  };

  sops.secrets =
    let
      user = config.systemd.services.hedgedoc.serviceConfig.User;
    in
    {
      hedgedoc_session_secret.owner = user;
      "hedgedoc/oidc_secret".owner = user;
      hedgedoc_ldap_search = {
        key = "portunus/search-password";
        owner = user;
      };
    };

  systemd.services.hedgedoc.preStart = lib.mkBefore ''
    export SESSION_SECRET="$(cat ${config.sops.secrets.hedgedoc_session_secret.path})"
    export OIDC_SECRET="$(cat ${config.sops.secrets."hedgedoc/oidc_secret".path})"
  '';
}

