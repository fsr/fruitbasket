{ config, pkgs, ... }:
  let 
    domain = "monitoring.${config.networking.domain}";
  in {
    # grafana configuration
    services.grafana = {
      enable = true;
      port = 2342;
    };
    
    services.prometheus = {
      enable = true;
      port = 9001;
    };

    # nginx reverse proxy
    services.nginx.virtualHosts.${domain} = {
      locations."/" = {
          proxyPass = "http://localhost:${toString config.services.grafana.port}";
          proxyWebsockets = true;
      };
    };
}
