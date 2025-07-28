{ config, lib, pkgs, ... }:
let
  domain = "git.${config.networking.domain}";
  gitUser = "git";
in
{
  imports = [
    ./actions.nix
  ];
  sops.secrets.gitea_ldap_search = {
    key = "portunus/search-password";
    owner = config.services.forgejo.user;
  };

  users.users.${gitUser} = {
    isSystemUser = true;
    home = config.services.forgejo.stateDir;
    group = gitUser;
    useDefaultShell = true;
  };
  users.groups.${gitUser} = { };

  services.forgejo = {
    enable = true;
    user = gitUser;
    group = gitUser;
    package = pkgs.forgejo;
    lfs.enable = true;

    database = {
      type = "postgres";
      name = "git"; # legacy
      createDatabase = true;
      user = gitUser;
    };

    # TODO: enable periodic dumps of the DB and repos, maybe use this for backups?
    # dump = { };

    settings = {
      DEFAULT = {
        APP_NAME = "iFSR Git";
      };
      server = {
        PROTOCOL = "http+unix";
        DOMAIN = domain;
        SSH_DOMAIN = config.networking.domain;
        ROOT_URL = "https://${domain}";
        OFFLINE_MODE = true; # disable use of CDNs
      };
      log.LEVEL = "Warn";
      database.LOG_SQL = false;
      service = {
        DISABLE_REGISTRATION = true;
        ENABLE_NOTIFY_MAIL = true;
        NO_REPLY_ADDRESS = "noreply.${config.networking.domain}";
      };
      "service.explore".DISABLE_USERS_PAGE = true;
      openid = {
        ENABLE_OPENID_SIGNIN = false;
        ENABLE_OPENID_SIGNUP = false;
      };
      mailer = {
        ENABLED = true;
        FROM = "\"iFSR Git\" <git@${config.networking.domain}>";
        SMTP_ADDR = "localhost";
        SMTP_PORT = 25;
      };
      session = {
        COOKIE_SECURE = true;
        PROVIDER = "db";
      };
      actions.ENABLED = true;
      # federation.ENABLED = true;
      webhook.ALLOWED_HOST_LIST = "*.ifsr.de";
      cors = {
        ENABLED = true;
        ALLOW_DOMAIN = "https://ifsr.de";
      };
      oauth2_client = {
        ENABLE_AUTO_REGISTRATION=true;
        ACCOUNT_LINKING="auto";
      };
    };
  };

  services.nginx.virtualHosts.${domain} = {
    locations."/" = {
      proxyPass = "http://unix:${config.services.anubis.instances.forgejo.settings.BIND}";
      proxyWebsockets = true;
    };
    # These paths are used by Decap and don't work when routed through anubis
    locations."/login/oauth/access_token".proxyPass = "http://unix:${config.services.forgejo.settings.server.HTTP_ADDR}:";
    locations."/api/v1".proxyPass = "http://unix:${config.services.forgejo.settings.server.HTTP_ADDR}:";

    locations."/api/v1/users/search".return = "403";
  };

  services.anubis.instances.forgejo.settings = {
    TARGET = "unix://${config.services.forgejo.settings.server.HTTP_ADDR}";
    SERVE_ROBOTS_TXT = true;
  };
}
