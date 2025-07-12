{ config, ... }:
let
  homeserverDomain = config.services.matrix-synapse.settings.server_name;
in
{
  services.postgresql = {
    enable = true;
    ensureUsers = [{
      name = "mautrix-telegram";
      ensureDBOwnership = true;
    }];
    ensureDatabases = [ "mautrix-telegram" ];
  };

  sops.secrets.mautrix-telegram_env = { };

  services.mautrix-telegram = {
    enable = true;

    environmentFile = config.sops.secrets.mautrix-telegram_env.path;
    registerToSynapse = true;

    settings = {
      homeserver = {
        address = "http://[::1]:8008";
        domain = homeserverDomain;
      };

      appservice = rec {
        # Use postgresql instead of sqlite
        database = "postgresql:///mautrix-telegram?host=/run/postgresql";
        port = 8082;
        address = "http://localhost:${toString port}";
      };

      bridge = {
        relaybot.authless_portals = false;
        permissions = {
          # Add yourself here temporarily
          "@admin:${homeserverDomain}" = "admin";
        };
        relay_user_distinguishers = [ ];
      };
    };
  };
}
