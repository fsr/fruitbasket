{ config, options, lib, pkgs, ... }:
let
  homeserverDomain = config.services.matrix-synapse.settings.server_name;
  registrationFileSynapse = "/var/lib/matrix-synapse/telegram-registration.yaml";
  registrationFileMautrix = "/var/lib/mautrix-telegram/telegram-registration.yaml";
  settingsFile = builtins.head (builtins.match ".*--config='(.*)' \\\\.*" config.systemd.services.mautrix-telegram.preStart);
in
{
  services.postgresql = {
    enable = true;
    ensureUsers = [{
      name = "mautrix-telegram";
      ensurePermissions = {
        "DATABASE \"mautrix-telegram\"" = "ALL PRIVILEGES";
      };
    }];
    ensureDatabases = [ "mautrix-telegram" ];
  };

  sops.secrets.mautrix-telegram_env = { };

  services.matrix-synapse.settings.app_service_config_files = [
    # The registration file is automatically generated after starting the
    # appservice for the first time.
    registrationFileSynapse
  ];

  systemd.tmpfiles.rules = [
    # copy registration file over to synapse
    "C ${registrationFileSynapse} - - - - ${registrationFileMautrix}"
    "Z /var/lib/matrix-synapse/ - matrix-synapse matrix-synapse - -"
  ];

  services.mautrix-telegram = {
    enable = true;

    environmentFile = config.sops.secrets.mautrix-telegram_env.path;

    settings = {
      homeserver = {
        address = "http://[::1]:8008";
        domain = homeserverDomain;
      };

      appservice = rec {
        # Use postgresql instead of sqlite
        database = "postgresql:///mautrix-telegram?host=/run/postgresql";
        port = 8082;
        address = "localhost:${toString port}";
      };

      bridge = {
        relaybot.authless_portals = false;
        permissions = {
          "@admin:${homeserverDomain}" = "admin";
        };
        relay_user_distinguishers = [ ];
      };
    };
  };

  # If we don't explicitly set {a,h}s_token, mautrix-telegram will try to read them from the registrationFile
  # and write them to the settingsFile in /nix/store, which obviously fails.
  systemd.services.mautrix-telegram.serviceConfig.ExecStart =
    lib.mkForce (pkgs.writeShellScript "start" ''
      export MAUTRIX_TELEGRAM_APPSERVICE_AS_TOKEN=$(grep as_token ${registrationFileMautrix} | cut -d' ' -f2-)
      export MAUTRIX_TELEGRAM_APPSERVICE_HS_TOKEN=$(grep hs_token ${registrationFileMautrix} | cut -d' ' -f2-)

      ${pkgs.mautrix-telegram}/bin/mautrix-telegram --config='${settingsFile}'
    '');
}
