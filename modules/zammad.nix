{ config, lib, ... }:
let
  domain = "tickets.${config.networking.domain}";
in
{
  services.zammad = {
    enable = true;
    database = {
      createLocally = true;
      type = "PostgreSQL";
    };
    redis.port = 6380;
    port = 8085;
    secretKeyBaseFile = config.sops.secrets."zammad_secret".path;
  };


  services.redis = {
    servers.zammad = {
      port = lib.mkForce 6380;
      enable = true;
    };
  };
  # disably spammy logs
  systemd.services.zammad-web.preStart = ''
    sed -i -e "s|debug|warn|" ./config/environments/production.rb 
  '';

  services.nginx.virtualHosts.${domain} = {
    locations."/" = {
      proxyPass = "http://localhost:${toString config.services.zammad.port}";
    };
    locations."/ws" = {
      proxyPass = "http://localhost:${toString config.services.zammad.websocketPort}";
      proxyWebsockets = true;
    };
  };

  sops.secrets."zammad_secret".owner = "zammad";
}
