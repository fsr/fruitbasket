{ pkgs, config, ... }:
{
  services = {
    nginx = {
      virtualHosts = {
        "stream.${config.networking.domain}" = {
          enableACME = true;
          forceSSL = true;
          locations."/" =
            let
              cfg = config.services.owncast;
            in
            {
              proxyPass = "http://${toString cfg.listen}:${toString cfg.port}";
              proxyWebsockets = true;
            };
        };
      };
    };
    owncast = {
      enable = true;
      port = 13142;
      listen = "[::ffff:127.0.0.1]";
      openFirewall = true;
      rtmp-port = 1935;
    };
  };
}
