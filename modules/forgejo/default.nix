{ config, lib, pkgs, ... }:
let
  domain = "git.${config.networking.domain}";
  gitUser = "git";
in
{
  # imports = [
  #   ./actions.nix
  # ];
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
      federation.ENABLED = true;
    };
  };

  systemd.services.forgejo.preStart =
    let
      exe = lib.getExe config.services.forgejo.package;
      portunus = config.services.portunus;
      basedn = "ou=users,${portunus.ldap.suffix}";
      ldapConfigArgs = ''
        --name LDAP \
        --active \
        --security-protocol unencrypted \
        --host '${portunus.domain}' \
        --port 389 \
        --user-search-base '${basedn}' \
        --user-filter '(&(objectClass=posixAccount)(uid=%s))' \
        --admin-filter '(isMemberOf=cn=admins,ou=groups,${portunus.ldap.suffix})' \
        --username-attribute uid \
        --firstname-attribute givenName \
        --surname-attribute sn \
        --email-attribute mail \
        --public-ssh-key-attribute sshPublicKey \
        --bind-dn 'uid=search,${basedn}' \
        --bind-password "`cat ${config.sops.secrets.gitea_ldap_search.path}`" \
        --synchronize-users
      '';
    in
    lib.mkAfter /* sh */ ''
      # Check if LDAP is already configured
      ldap_line=$(${exe} admin auth list | grep "LDAP" | head -n 1)

      if [[ -n "$ldap_line" ]]; then
        # update ldap config
        id=$(echo "$ldap_line" | ${pkgs.gawk}/bin/awk '{print $1}')
        ${exe} admin auth update-ldap --id $id ${ldapConfigArgs}
      else
        # initially configure ldap
        ${exe} admin auth add-ldap ${ldapConfigArgs}
      fi
    '';

  services.nginx.virtualHosts.${domain} = {
    locations."/" = {
      proxyPass = "http://unix:${config.services.forgejo.settings.server.HTTP_ADDR}:/";
      proxyWebsockets = true;
    };
    locations."/api/v1/users/search".return = "403";
  };
}
