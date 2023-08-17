{ pkgs, config, ... }:
{
  services = {
    nginx = {
      virtualHosts = {
        # "stream.${config.fsr.domain}" = {
        "stream.ifsr.de" = {
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
      #streamConfig = ''
      #  server {
      #  listen            1935;
      #  proxy_pass        [::1]:1935;
      #  proxy_buffer_size 32k;
      #}
      #'';
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
