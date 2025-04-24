{ config, ... }:
let cfg = config.services.owncast;
in
{
  services = {
    nginx = {
      virtualHosts = {
        "stream.${config.networking.domain}" = {
          locations."/" =
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
      rtmp-port = 1935;
    };
  };
  networking.firewall = {
    extraInputRules = ''
      ip saddr {141.30.0.0/16, 141.76.0.0/16} tcp dport ${toString cfg.rtmp-port} accept comment "Allow rtmp access from campus nets"
    '';
  };
}
